defmodule ER.Destinations.Webhook do
  require Logger
  alias ER.Events.Event

  def request(
        url,
        event,
        destination_id,
        destination_topic_name,
        destination_topic_identifier,
        signing_secret
      ) do
    body = Event.json_encode!(event)

    headers =
      build_headers(
        body,
        signing_secret,
        destination_id,
        destination_topic_name,
        destination_topic_identifier
      )

    HTTPoison.post(url, body, headers)
  end

  defp build_headers(
         body,
         signing_secret,
         destination_id,
         destination_topic_name,
         destination_topic_identifier
       ) do
    event_relay_signature = Event.signature(body, signing_secret: signing_secret)

    [
      {"Content-Type", "application/json"},
      {"X-Event-Relay-Signature", event_relay_signature},
      {"X-Event-Relay-Destination-Id", destination_id},
      {"X-Event-Relay-Destination-Topic-Name", destination_topic_name},
      {"X-Event-Relay-Destination-Topic-Identifier", destination_topic_identifier}
    ]
  end

  def to_map(%{status_code: status_code, headers: headers}) do
    %{status_code: status_code, headers: headers_to_map(headers)}
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
