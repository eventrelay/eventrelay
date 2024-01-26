defmodule ER.Destinations.Webhook do
  require Logger
  alias ER.Events.Event
  alias ER.Destinations.Destination

  def request(
        destination,
        event,
        now \\ DateTime.utc_now()
      ) do
    url = destination.config["endpoint_url"]

    payload = to_payload(event, destination, now)

    unix_timestamp = DateTime.to_unix(now)

    signature =
      Webhoox.Authentication.StandardWebhook.sign(
        event.id,
        unix_timestamp,
        payload,
        destination.signing_secret
      )

    Req.post(
      url: url,
      body: Jason.encode!(payload),
      headers: [
        content_type: "application/json",
        webhook_id: event.id,
        webhook_timestamp: unix_timestamp,
        webhook_signature: signature,
        x_event_relay_event_id: event.id,
        x_event_relay_destination_id: destination.id,
        x_event_relay_topic_name: event.topic_name,
        x_event_relay_topic_identifier: event.topic_identifier
      ]
    )
  end

  def to_payload(event, destination, now) do
    data =
      event
      |> Event.to_map()
      |> Destination.transform_event(destination)
      |> Map.put_new(:id, event.id)

    %{
      timestamp: Flamel.Moment.to_iso8601(now),
      data: data,
      type: data[:name]
    }
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
