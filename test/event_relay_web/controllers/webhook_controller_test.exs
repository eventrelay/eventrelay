defmodule ERWeb.WebhookControllerTest do
  use ERWeb.ConnCase

  alias ER.Events
  import ER.Factory

  def setup_auth(%{conn: conn, topic: topic}) do
    ingestor = insert(:ingestor, topic: topic)
    creds = Base.encode64("#{ingestor.key}:#{ingestor.secret}")

    {:ok, conn: put_req_header(conn, "authorization", "Basic #{creds}"), ingestor: ingestor}
  end

  setup %{conn: conn} do
    {:ok, topic} = Events.create_topic(%{name: "webhooks"})

    {:ok, conn: put_req_header(conn, "accept", "application/json"), topic: topic}
  end

  describe "ingest webhook" do
    setup [:setup_auth]

    test "creates an event and renders 200", %{conn: conn, topic: topic, ingestor: ingestor} do
      data = %{"type" => "user.updated", "data" => %{"id" => 123, "name" => "Riley"}}

      conn =
        post(conn, ~p"/webhooks/ingest/#{ingestor}", data)

      assert text_response(conn, 200) == "OK"

      events = ER.Events.list_events_for_topic(topic_name: topic.name, topic_identifier: nil)

      event = List.last(events)

      # TODO: move event name to ingestor 
      assert event.name == "webhook.inbound"
      assert event.topic_name == ingestor.topic_name
      assert event.data == data
      assert event.source == ingestor.source
    end
  end

  describe "ingest webhook with invalid creds" do
    test "returns 401", %{conn: _conn} do
      # TODO: write
    end
  end
end
