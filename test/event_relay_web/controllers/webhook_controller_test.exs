defmodule ERWeb.WebhookControllerTest do
  use ERWeb.ConnCase

  alias ER.Events
  import ER.Factory

  def setup_auth(%{conn: conn, topic: topic}) do
    source = insert(:source, topic: topic)
    creds = Base.encode64("#{source.key}:#{source.secret}")

    {:ok, conn: put_req_header(conn, "authorization", "Basic #{creds}"), source: source}
  end

  setup %{conn: conn} do
    {:ok, topic} = Events.create_topic(%{name: "webhooks"})

    {:ok, conn: put_req_header(conn, "accept", "application/json"), topic: topic}
  end

  describe "ingest webhook" do
    setup [:setup_auth]

    test "creates an event and renders 200", %{conn: conn, topic: topic, source: source} do
      data = %{"type" => "user.updated", "data" => %{"id" => 123, "name" => "Riley"}}

      conn =
        post(conn, ~p"/webhooks/ingest/#{source}", data)

      assert text_response(conn, 200) == "OK"

      events =
        ER.Events.list_events_for_topic(topic.name, topic_identifier: nil, return_batch: false)

      event = List.last(events)

      # TODO: move event name to source 
      assert event.name == "webhook.inbound"
      assert event.topic_name == source.topic_name
      assert event.data == data
      assert event.source == source.source
    end
  end

  describe "ingest webhook with invalid creds" do
    test "returns 401", %{conn: _conn} do
      # TODO: write
    end
  end
end
