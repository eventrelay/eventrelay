defmodule ER.Subscriptions.Delivery.Server do
  @moduledoc """
  Manages the delivery of a webhook
  """
  require Logger
  use GenServer
  use ER.Server

  def handle_continue(:load_state, %{id: id} = state) do
    delivery = ER.Subscriptions.get_delivery!(id)

    state =
      state
      |> Map.put("delivery", delivery)
      |> Map.put("subscription", delivery.subscription)
      |> Map.put("event", delivery.event)
      |> Map.put("attempt_count", 0)
      |> Map.put("retry_delay", 30)
      |> Map.put("max_attempts", 10)

    Logger.debug("Delivery server started for #{inspect(delivery)}")
    Process.send(self(), :attempt, [])

    {:noreply, state}
  end

  def handle_info(
        :attempt,
        %{
          "subscription" => subscription,
          "event" => event,
          "delivery" => delivery,
          "retry_delay" => retry_delay
        } = state
      ) do
    Logger.debug(
      "#{__MODULE__}.handle_info(:attempt, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    webhook_url = subscription.config["endpoint_url"]

    response =
      HTTPoison.post(webhook_url, Jason.encode!(event), [
        {"Content-Type", "application/json"},
        {"X-Event-Relay-Subscription-Id", subscription.id},
        {"X-Event-Relay-Subscription-Topic-Name", subscription.topic_name},
        {"X-Event-Relay-Subscription-Topic-Identifier", subscription.topic_identifier}
      ])
      |> handle_response()

    attempts = [%{response: response, attempted_at: DateTime.utc_now()} | delivery.attempts]
    delivery = ER.Subscriptions.update_delivery(delivery, %{attempts: attempts})

    state =
      state
      |> Map.put("attempt_count", state["attempt_count"] + 1)
      |> Map.put("delivery", delivery)

    IO.inspect(response: response, state: state)

    cond do
      success?(response) ->
        Logger.debug("Webhook #{inspect(subscription)} delivered successfully")
        {:stop, :shutdown, state}

      retry?(state) ->
        Logger.debug(
          "Webhook #{inspect(subscription)} failed, retrying in #{retry_delay} seconds"
        )

        retry_delay = retry_delay * 2
        state = state |> Map.put("retry_delay", retry_delay)
        Process.send_after(self(), :attempt, retry_delay, [])
        {:noreply, state}

      true ->
        Logger.debug("Webhook #{inspect(delivery)} failed, not retrying")

        {:stop, :shutdown, state}
    end

    # if ok then shutdown the delivery server
    # if not ok and can retry then schedule a retry
    # if not ok and can't retry then shutdown the delivery server and mark the delivery as failed

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

  def handle_response({:ok, %HTTPoison.Response{status_code: status_code, body: body}}) do
    Logger.debug(
      "Webhook response: status_code=#{inspect(status_code)} and body=#{inspect(body)}"
    )

    if status_code in 200..299 do
      {:ok, status_code}
    else
      {:error, Plug.Conn.Status.reason_phrase(status_code)}
    end
  end

  def handle_response({:error, error}) do
    Logger.error("Webhook error: #{inspect(error)}")
    {:error, error}
  end

  @spec name(binary()) :: binary()
  def name(id) do
    "delivery:" <> id
  end

  def terminate(reason, state) do
    Logger.debug("Delivery server terminated: #{inspect(reason)}")
    Logger.debug("Delivery server state: #{inspect(state)}")
    # TODO: save state to redis if needed or delete it if this is a good termination
  end
end
