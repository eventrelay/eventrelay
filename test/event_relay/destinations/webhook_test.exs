defmodule ER.Destinations.WebhookTest do
  use ER.DataCase
  import ER.Factory
  alias ER.Destinations.Webhook
  alias ER.Events
  use Mimic

  describe "request/2" do
    setup do
      {:ok, topic} = ER.Events.create_topic(%{name: "users"})
      destination = insert(:destination, topic: topic)

      {:ok, event} =
        params_for(:event,
          topic: topic,
          name: "user.updated",
          group_key: "target_group",
          source: "app",
          offset: 1,
          data: %{"first_name" => "Thomas"}
        )
        |> Events.create_event_for_topic()

      {:ok, topic: topic, event: event, destination: destination}
    end

    test "the payload conforms to the standard webhook spec", %{
      event: event,
      destination: destination
    } do
      now = DateTime.utc_now()

      Req
      |> expect(:post, fn opts ->
        body = opts[:body] |> Jason.decode!()
        assert Map.has_key?(body, "timestamp")
        assert Map.has_key?(body, "type")
        assert Map.has_key?(body, "data")

        expected_data =
          event
          |> Jason.encode!()
          |> Jason.decode!()

        assert Map.get(body, "timestamp") == Flamel.Moment.to_iso8601(now)
        assert Map.get(body, "type") == event.name
        assert Map.get(body, "data") == expected_data
      end)

      Webhook.request(destination, event, now)
    end

    test "the headers values are set properly", %{
      event: event,
      destination: destination
    } do
      now = DateTime.utc_now()

      Req
      |> expect(:post, fn opts ->
        headers = opts[:headers]

        expected_signature =
          Webhoox.Authentication.StandardWebhook.sign(
            event.id,
            DateTime.to_unix(now),
            Webhook.to_payload(event, now),
            destination.signing_secret
          )

        assert Keyword.has_key?(headers, :webhook_signature)
        assert Keyword.has_key?(headers, :webhook_id)
        assert Keyword.has_key?(headers, :webhook_timestamp)

        assert headers[:webhook_signature] == expected_signature
        assert headers[:webhook_id] == event.id
        assert headers[:webhook_timestamp] == DateTime.to_unix(now)

        assert headers[:x_event_relay_event_id] == event.id
        assert headers[:x_event_relay_topic_name] == event.topic_name
        assert headers[:x_event_relay_topic_identifier] == event.topic_identifier
        assert headers[:x_event_relay_destination_id] == destination.id
      end)

      Webhook.request(destination, event, now)
    end
  end
end
