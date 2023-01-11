defmodule ER.Subscriptions.Delivery.Server do
  @moduledoc """
  Manages the delivery of a webhook
  """
  require Logger
  use GenServer
  use ER.Server
  import ER, only: [unwrap: 1]
  alias ER.Events.Event

  def handle_continue(
        :load_state,
        %{
          "event" => event,
          "subscription" => subscription,
          "delivery" => delivery
        } = state
      ) do
    # Check Redis cache to see if we have a delivery in progress
    # if we do, then we need to load the delivery and then
    # if not then we need to initialize normally

    # delivery = ER.Subscriptions.get_delivery_for_topic!(id, topic_name: topic_name)
    IO.inspect(delivery, label: "delivery")

    #     event =
    #       ER.Events.get_event_for_topic!(delivery.event_id,
    #         topic_name: delivery.subscription.topic_name
    #       )

    state =
      state
      |> Map.put("delivery_attempts", delivery.attempts)
      |> Map.put("subscription_endpoint_url", subscription.config["endpoint_url"])
      |> Map.put("subscription_id", subscription.id)
      |> Map.put("subscription_name", subscription.name)
      |> Map.put("subscription_topic_name", subscription.topic_name)
      |> Map.put("subscription_topic_identifier", subscription.topic_identifier)
      # this could be a problem with serialization
      |> Map.put("event", event)
      |> Map.put("attempt_count", 0)
      |> Map.put("retry_delay", 30_000)
      |> Map.put("max_attempts", 10)

    Logger.debug("Delivery server started for #{inspect(delivery)}")
    Process.send(self(), :attempt, [])

    {:noreply, state}
  end

  def handle_info(
        :attempt,
        %{
          "subscription_endpoint_url" => webhook_url,
          "subscription_id" => subscription_id,
          "subscription_topic_name" => subscription_topic_name,
          "subscription_topic_identifier" => subscription_topic_identifier,
          "event" => event,
          "delivery_attempts" => delivery_attempts
        } = state
      ) do
    Logger.debug(
      "#{__MODULE__}.handle_info(:attempt, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    response =
      HTTPoison.post(webhook_url, Jason.encode!(event), [
        {"Content-Type", "application/json"},
        {"X-Event-Relay-Subscription-Id", subscription_id},
        {"X-Event-Relay-Subscription-Topic-Name", subscription_topic_name},
        {"X-Event-Relay-Subscription-Topic-Identifier", subscription_topic_identifier}
      ])
      |> handle_response()

    delivery_attempts = [
      %{"response" => unwrap(response), "attempted_at" => DateTime.utc_now()} | delivery_attempts
    ]

    state =
      state
      |> Map.put("attempt_count", state["attempt_count"] + 1)
      |> Map.put("delivery_attempts", delivery_attempts)

    cond do
      success?(response) ->
        handle_success(state)

      retry?(state) ->
        handle_retry(state)

      true ->
        handle_failure(state)
    end
  end

  def handle_success(
        %{
          "delivery_attempts" => delivery_attempts,
          "subscription_id" => subscription_id,
          "event" => event,
          "id" => id,
          "delivery" => delivery
        } = state
      ) do
    Logger.debug(
      "Webhook subscription=#{inspect(subscription_id)} and delivery=#{inspect(id)} delivered successfully"
    )

    create_delivery_for_event(event, delivery, %{
      event_id: event.id,
      subscription_id: subscription_id,
      attempts: delivery_attempts,
      success: true
    })

    # delivery = ER.Subscriptions.get_delivery_for_topic!(id, topic_name: subscription_topic_name)
    # ER.Subscriptions.update_delivery(delivery, %{success: true, attempts: delivery_attempts})
    {:stop, :shutdown, state}
  end

  def handle_failure(
        %{
          "id" => id,
          "subscription_id" => subscription_id,
          "delivery_attempts" => delivery_attempts,
          "event" => event,
          "delivery" => delivery
        } = state
      ) do
    Logger.debug("Webhook delivery #{inspect(id)} failed, not retrying")

    create_delivery_for_event(event, delivery, %{
      event_id: event.id,
      subscription_id: subscription_id,
      attempts: delivery_attempts,
      success: false
    })

    # delivery = ER.Subscriptions.get_delivery_for_topic!(id, topic_name: subscription_topic_name)
    # ER.Subscriptions.update_delivery(delivery, %{success: false, attempts: delivery_attempts})
    {:stop, :shutdown, state}
  end

  def handle_retry(%{"subscription_id" => subscription_id, "retry_delay" => retry_delay} = state) do
    retry_delay = retry_delay * 2

    Logger.debug("Webhook #{inspect(subscription_id)} failed, retrying in #{retry_delay} seconds")

    state = state |> Map.put("retry_delay", retry_delay)
    Process.send_after(self(), :attempt, retry_delay, [])
    {:noreply, state}
  end

  def success?({:ok, _}) do
    true
  end

  def success?({:error, _}) do
    false
  end

  def retry?(%{"attempt_count" => attempt_count, "max_attempts" => max_attempts})
      when attempt_count < max_attempts do
    true
  end

  def retry?(_) do
    false
  end

  def create_delivery_for_event(%Event{topic_name: topic_name, durable: true}, delivery, attrs) do
    ER.Subscriptions.create_delivery_for_topic(
      topic_name,
      attrs,
      delivery
    )
  end

  def create_delivery_for_event(
        %Event{durable: false} = event,
        delivery,
        _attrs
      ) do
    Logger.debug(
      "Not creating delivery for non-durable event #{inspect(event)} and delivery #{inspect(delivery)}"
    )
  end

  # TODO Move this to a helper module
  def response_to_map(response) do
    %{status_code: response.status_code, headers: response_headers_to_map(response.headers)}
  end

  def response_headers_to_map(headers) do
    headers
    |> Enum.map(fn {k, v} -> {String.upcase(k), v} end)
    |> Enum.into(%{})
  end

  def error_response_to_map(%HTTPoison.Error{reason: reason}) do
    %{error_reason: reason}
  end

  def handle_response({:ok, %HTTPoison.Response{status_code: status_code, body: body} = response}) do
    Logger.debug(
      "Webhook response: status_code=#{inspect(status_code)} and body=#{inspect(body)}"
    )

    # TODO handle redirects better
    if status_code in 200..299 do
      {:ok, response_to_map(response)}
    else
      {:error, response_to_map(response)}
    end
  end

  def handle_response({:error, error}) do
    Logger.error("Webhook error: #{inspect(error)}")

    {:error, error_response_to_map(error)}
  end

  @spec name(binary()) :: binary()
  def name(id) do
    "delivery:" <> id
  end

  def handle_terminate(reason, state) do
    case reason do
      :shutdown ->
        :ok

      _ ->
        Logger.error("Delivery server terminated unexpectedly: #{inspect(reason)}")
        Logger.debug("Delivery server state: #{inspect(state)}")
    end
  end
end
