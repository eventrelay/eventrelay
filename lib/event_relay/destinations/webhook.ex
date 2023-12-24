defmodule ER.Destinations.Webhook do
  require Logger
  alias ER.Events.Event

  def request(
        url,
        event,
        destination_id,
        destination_topic_name,
        destination_topic_identifier,
        destination_signing_secret
      ) do
    body = Event.json_encode!(event)

    HTTPoison.post(url, body, [
      {"Content-Type", "application/json"},
      {"X-Event-Relay-Signature",
       Event.signature(body, signing_secret: destination_signing_secret)},
      {"X-Event-Relay-Destination-Id", destination_id},
      {"X-Event-Relay-Destination-Topic-Name", destination_topic_name},
      {"X-Event-Relay-Destination-Topic-Identifier", destination_topic_identifier}
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