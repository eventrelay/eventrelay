defmodule ER.Destinations.WebhookTest do
  use ER.DataCase
  import ER.Factory
  alias ER.Destinations.Webhook
  alias ER.Events
  alias ER.Events.Event
  use Mimic

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

  describe "to_payload/3" do
    test "transforms the payload data", %{destination: destination, event: event} do
      now = DateTime.utc_now()

      insert(:transformer,
        script: """
        {
            "data": {{event.data | json}},
            "name": "another.name",
            "source": "internal",
            "topic_name": "{{context.topic_name}}",
            "context": {{event.context | json}}
        }
        """,
        type: :liquid,
        destination: destination,
        return_type: :map,
        query: "name == '#{event.name}'"
      )

      assert Webhook.to_payload(event, destination, now) == %{
               data: %{
                 id: event.id,
                 data: %{"first_name" => "Thomas"},
                 name: "another.name",
                 context: %{},
                 source: "internal",
                 topic_name: "users"
               },
               timestamp: Flamel.Moment.to_iso8601(now),
               type: "another.name"
             }
    end
  end

  describe "request/2" do
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
          Event.to_map(event)
          |> Flamel.Map.stringify_keys()
          |> then(fn data ->
            Enum.reduce(data, %{}, fn
              {key, %DateTime{} = value}, acc ->
                Map.put(acc, key, Flamel.Moment.to_iso8601(value))

              {key, value}, acc ->
                Map.put(acc, key, value)
            end)
          end)

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
            Webhook.to_payload(event, destination, now),
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
