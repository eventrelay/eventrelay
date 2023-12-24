defmodule ER.Destinations.Delivery.S3.ServerTest do
  use ER.DataCase
  alias ER.Destinations.Delivery.S3.Server
  alias ER.Destinations

  import ER.Test.Setups
  import ER.Test.Helpers

  describe "build_events_file_name/1" do
    test "returns file name that includes date as a dir and ISO8601 in the file name" do
      now = ~U[2023-01-01 00:00:00Z]

      assert Server.build_events_file_name(now) == "/2023-01-01/2023-01-01T00:00:00Z-events.jsonl"
    end
  end

  describe "jsonl_encode_delivery_events/1" do
    setup [:setup_topic, :setup_deliveries]

    test "encodes events to jsonl", %{destination: destination, topic: topic} do
      deliveries =
        Destinations.list_deliveries_for_destination(
          topic.name,
          destination.id,
          status: :pending
        )

      {jsonl, events} = Server.jsonl_encode_delivery_events(topic.name, deliveries)
      parsed_jsonl = parse_jsonl(jsonl)

      assert Enum.count(parsed_jsonl) == 2
      first_event = List.first(events)

      first_parsed_event = List.first(parsed_jsonl)
      assert first_event.id == first_parsed_event["id"]
    end
  end
end
