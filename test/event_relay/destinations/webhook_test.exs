defmodule ER.Destinations.WebhookTest do
  use ER.DataCase
  import ER.Factory
  alias ER.{Destinations, Events}
  alias Destinations.Webhook
  alias Events.Event

  describe "webhook/6" do
    setup do
      bypass = Bypass.open()
      {:ok, topic} = Events.create_topic(%{name: "users"})

      webhook_url = "http://localhost:#{bypass.port}"

      destination =
        insert(:destination,
          name: "users_webhook",
          topic: topic,
          config: %{"endpoint_url" => webhook_url}
        )

      event = insert(:event, name: "user.created", data: %{"first_name" => "Bill"})

      {:ok, bypass: bypass, webhook_url: webhook_url, destination: destination, event: event}
    end

    test "returns HTTP 200 when successful", %{
      bypass: bypass,
      webhook_url: webhook_url,
      destination: destination,
      event: event
    } do
      response_body = Jason.encode!(event)

      Bypass.expect(bypass, fn conn ->
        assert "POST" == conn.method
        assert "/" == conn.request_path
        Plug.Conn.resp(conn, 200, response_body)
      end)

      event_relay_signature =
        Event.signature(response_body, signing_secret: destination.signing_secret)

      event_relay_destination_id = destination.id

      assert {:ok,
              %HTTPoison.Response{
                status_code: 200,
                body: response_body,
                headers: [
                  {"cache-control", "max-age=0, private, must-revalidate"},
                  {"content-length", _content_length},
                  {"date", _date},
                  {"server", "Cowboy"}
                ],
                request_url: webhook_url,
                request: %HTTPoison.Request{
                  method: :post,
                  url: webhook_url,
                  headers: [
                    {"Content-Type", "application/json"},
                    {"X-Event-Relay-Signature", event_relay_signature},
                    {"X-Event-Relay-Destination-Id", destination_id},
                    {"X-Event-Relay-Destination-Topic-Name", "users"},
                    {"X-Event-Relay-Destination-Topic-Identifier", nil}
                  ],
                  body: response_body,
                  params: %{},
                  options: []
                }
              }} = webhook_request(webhook_url, event, destination)
    end

    test "returns econnrefused error when unexpected outage", %{
      bypass: bypass,
      webhook_url: webhook_url,
      destination: destination,
      event: event
    } do
      Bypass.down(bypass)

      assert {:error, %HTTPoison.Error{reason: :econnrefused, id: nil}} =
               webhook_request(webhook_url, event, destination)
    end
  end

  defp webhook_request(webhook_url, event, destination) do
    Webhook.request(
      webhook_url,
      event,
      destination.id,
      destination.topic_name,
      destination.topic_identifier,
      destination.signing_secret
    )
  end
end
