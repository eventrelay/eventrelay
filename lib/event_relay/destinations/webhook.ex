defmodule ER.Destinations.Webhook do
  require Logger
  alias ER.Events.Event

  def request(
        destination,
        event
      ) do
    body = Event.json_encode!(event)
    signature = Event.signature(body, signing_secret: destination.signing_secret)
    url = destination.config["endpoint_url"]

    Req.post(
      url: url,
      body: body,
      headers: [
        content_type: "application/json",
        x_event_relay_signature: signature,
        x_event_relay_destination_id: destination.id,
        x_event_relay_destination_topic_name: destination.topic_name,
        x_event_relay_destination_topic_identifier: destination.topic_identifier
      ]
    )
  end

  def to_map(response) do
    %{status: response.status, headers: headers_to_map(response.headers)}
  end

  def headers_to_map(headers) do
    headers
    |> Enum.map(fn {k, v} -> {String.upcase(k), v} end)
    |> Enum.into(%{})
  end

  def handle_response({:ok, %Req.Response{status: status, body: body} = response}) do
    Logger.debug("Webhook response: status=#{inspect(status)} and body=#{inspect(body)}")

    # TODO handle redirects better
    if status in 200..299 do
      {:ok, to_map(response)}
    else
      {:error, to_map(response)}
    end
  end

  def handle_response({:error, error}) do
    {:error, %{"error" => "#{inspect(error)}"}}
  end
end
