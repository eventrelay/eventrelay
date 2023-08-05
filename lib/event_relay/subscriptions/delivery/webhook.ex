defmodule ER.Subscriptions.Delivery.Webhook do
  require Logger
  alias ER.Subscriptions.Subscription
  alias ER.Events.Event

  def push(%Subscription{} = subscription, %Event{} = event) do
    Logger.debug("Pushing event to webhook #{inspect(subscription)}")
    topic_name = subscription.topic_name

    delivery = ER.Subscriptions.build_delivery_for_topic(topic_name)
    Logger.debug("Created delivery #{inspect(delivery)}")

    ER.Subscriptions.Webhook.Delivery.Server.factory(delivery.id, %{
      "topic_name" => topic_name,
      "delivery" => delivery,
      "subscription" => subscription,
      "event" => event
    })
  end

  def request(
        url,
        event,
        subscription_id,
        subscription_topic_name,
        subscription_topic_identifier
      ) do
    HTTPoison.post(url, Jason.encode!(event), [
      {"Content-Type", "application/json"},
      {"X-Event-Relay-Subscription-Id", subscription_id},
      {"X-Event-Relay-Subscription-Topic-Name", subscription_topic_name},
      {"X-Event-Relay-Subscription-Topic-Identifier", subscription_topic_identifier}
    ])
  end

  def to_map(response) do
    %{status_code: response.status_code, headers: headers_to_map(response.headers)}
  end

  def headers_to_map(headers) do
    headers
    |> Enum.map(fn {k, v} -> {String.upcase(k), v} end)
    |> Enum.into(%{})
  end

  def error_to_map(%HTTPoison.Error{reason: reason}) do
    %{error_reason: reason}
  end

  def handle_response({:ok, %HTTPoison.Response{status_code: status_code, body: body} = response}) do
    Logger.debug(
      "Webhook response: status_code=#{inspect(status_code)} and body=#{inspect(body)}"
    )

    # TODO handle redirects better
    if status_code in 200..299 do
      {:ok, to_map(response)}
    else
      {:error, to_map(response)}
    end
  end

  def handle_response({:error, error}) do
    Logger.error("Webhook error: #{inspect(error)}")

    {:error, error_to_map(error)}
  end
end
