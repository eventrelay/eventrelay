defmodule ERWeb.WebhookControllerTest do
  use ERWeb.ConnCase

  alias ER.Events
  import ER.Factory
  use Mimic

  @moduletag source_type: :webhook
  @moduletag source_event_name: "my.custom.event"
  @moduletag source_config: %{}

  def setup_auth(%{conn: conn, topic: topic} = context) do
    source =
      insert(:source,
        topic: topic,
        event_name: context.source_event_name,
        type: context.source_type,
        config: context.source_config
      )

    creds = Base.encode64("#{source.key}:#{source.secret}")

    {:ok, conn: put_req_header(conn, "authorization", "Basic #{creds}"), source: source}
  end

  def setup_destination(context) do
    destination = insert(:destination, topic: context.topic)

    {:ok, destination: destination}
  end

  setup %{conn: conn} do
    {:ok, topic} = Events.create_topic(%{name: "webhooks"})

    {:ok, conn: put_req_header(conn, "accept", "application/json"), topic: topic}
  end

  describe "ingest webhook" do
    setup [:setup_auth]

    test "creates an event and renders 200", %{
      conn: conn,
      topic: topic,
      source: source,
      source_event_name: source_event_name
    } do
      data = %{"type" => "user.updated", "data" => %{"id" => 123, "name" => "Riley"}}

      conn =
        post(conn, ~p"/webhooks/ingest/#{source}", data)

      assert text_response(conn, 200) == "OK"

      events =
        ER.Events.list_events_for_topic(topic.name, topic_identifier: nil, return_batch: false)

      event = List.last(events)

      assert event.name == source_event_name
      assert event.topic_name == source.topic_name
      assert event.data == data
      assert event.source == source.source
    end

    @tag source_event_name: nil
    test "creates an event with fallback event name and renders 200", %{
      conn: conn,
      topic: topic,
      source: source
    } do
      data = %{"type" => "user.updated", "data" => %{"id" => 123, "name" => "Riley"}}

      conn =
        post(conn, ~p"/webhooks/ingest/#{source}", data)

      assert text_response(conn, 200) == "OK"

      events =
        ER.Events.list_events_for_topic(topic.name, topic_identifier: nil, return_batch: false)

      event = List.last(events)

      assert event.name == "webhook.inbound"
      assert event.topic_name == source.topic_name
      assert event.data == data
      assert event.source == source.source
    end

    test "creates an event, transforms it and renders 200", %{
      conn: conn,
      topic: topic,
      source: source
    } do
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
        source: source,
        return_type: :map,
        query: "topic_name == '#{source.topic_name}'"
      )

      data = %{"type" => "user.updated", "data" => %{"id" => 123, "name" => "Riley"}}

      conn =
        post(conn, ~p"/webhooks/ingest/#{source}", data)

      assert text_response(conn, 200) == "OK"

      events =
        ER.Events.list_events_for_topic(topic.name, topic_identifier: nil, return_batch: false)

      event = List.last(events)

      assert event.name == "another.name"
      assert event.topic_name == source.topic_name
      assert event.data == data
      assert event.source == "internal"
    end

    test "returns 429 when hitting a rate limit", %{conn: conn, source: source} do
      ERWeb.RateLimiter
      |> expect(:check_rate, fn "publish_events", durable: true ->
        {:deny, "publish_events", 1_000, 1000}
      end)

      data = %{"type" => "user.updated", "data" => %{"id" => 123, "name" => "Riley"}}

      conn =
        post(conn, ~p"/webhooks/ingest/#{source}", data)

      assert text_response(conn, 429) ==
               "Rate limit exceeded for publish_events at 1000 requests per 1.0 second(s)"
    end
  end

  describe "ingest standard webhook" do
    @describetag source_type: :standard_webhook
    @describetag source_config: %{"signing_secret" => "abc123"}

    setup [:setup_auth, :setup_destination]

    test "creates an a verified event and renders a 200 when a valid standard webhook is received",
         %{conn: conn, topic: topic, source: source, destination: destination} do
      now = DateTime.utc_now()
      event_id = "123"

      payload = %{
        "timestamp" => Flamel.Moment.to_iso8601(now),
        "type" => "user.updated",
        "data" => %{"id" => event_id, "name" => "Riley"}
      }

      signature =
        Webhoox.Authentication.StandardWebhook.sign(
          event_id,
          DateTime.to_unix(now),
          payload,
          destination.signing_secret
        )

      conn =
        conn
        |> Plug.Conn.put_req_header("accept", "application/json")
        |> Plug.Conn.put_req_header("webhook-id", event_id)
        |> Plug.Conn.put_req_header("webhook-signature", signature)
        |> Plug.Conn.put_req_header(
          "webhook-timestamp",
          now |> DateTime.to_unix() |> Flamel.to_string()
        )

      conn =
        post(conn, ~p"/webhooks/ingest/#{source}", payload)

      assert text_response(conn, 200) == "OK"

      events =
        ER.Events.list_events_for_topic(topic.name, topic_identifier: nil, return_batch: false)

      event = List.last(events)

      # TODO: move event name to source 
      assert event.name == "user.updated"
      assert event.topic_name == source.topic_name
      assert event.data == payload["data"]
      assert event.source == source.source
    end
  end

  describe "ingest webhook with invalid creds" do
    test "returns 401", %{conn: _conn} do
      # TODO: write
    end
  end
end
