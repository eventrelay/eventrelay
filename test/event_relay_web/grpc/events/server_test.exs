defmodule ERWeb.Grpc.EventRelay.Events.ServerTest do
  use ER.DataCase

  alias ERWeb.Grpc.EventRelay.Events.Server
  alias ER.Events
  import ER.Factory

  alias ERWeb.Grpc.Eventrelay.{
    PublishEventsRequest,
    NewEvent,
    PullEventsRequest,
    Filter
  }

  setup do
    {:ok, topic} = Events.create_topic(%{name: "log"})

    {:ok, topic: topic}
  end

  describe "publish_events/2" do
    test "publishes events", %{topic: topic} do
      event_name = "entry.created"
      group_key = "groupkey"

      request = %PublishEventsRequest{
        topic: topic.name,
        durable: true,
        events: [
          %NewEvent{
            name: event_name,
            data: Jason.encode!(%{}),
            source: "test",
            group_key: group_key
          }
        ]
      }

      result = Server.publish_events(request, nil)

      [event | _] = result.events

      assert event.name == event_name
      assert event.group_key == group_key

      events = Events.list_events_for_topic(topic_name: topic.name)
      assert Enum.count(events) == 1
    end

    test "raise RPCError if no topic is provided" do
      event_name = "entry.created"
      group_key = "groupkey"

      request = %PublishEventsRequest{
        durable: true,
        events: [
          %NewEvent{
            name: event_name,
            data: Jason.encode!(%{}),
            source: "test",
            group_key: group_key
          }
        ]
      }

      assert_raise GRPC.RPCError, "A topic must be provided to publish_events", fn ->
        Server.publish_events(request, nil)
      end
    end

    test "does not persit events if durable is false", %{topic: topic} do
      event_name = "entry.created"
      group_key = "groupkey"

      request = %PublishEventsRequest{
        topic: topic.name,
        durable: false,
        events: [
          %NewEvent{
            name: event_name,
            data: Jason.encode!(%{}),
            source: "test",
            group_key: group_key
          }
        ]
      }

      Server.publish_events(request, nil)
      events = Events.list_events_for_topic(topic_name: topic.name)
      assert Enum.count(events) == 0
    end
  end

  describe "pull_events/2" do
    test "returns events", %{topic: topic} do
      totals = [10, 30]

      Enum.each(totals, fn total ->
        attrs = params_for(:event, topic: topic)
        attrs = %{attrs | data: %{"cart" => %{"total" => total}}}
        ER.Events.create_event_for_topic(attrs)
      end)

      request = %PullEventsRequest{
        topic: topic.name,
        filters: []
      }

      result = Server.pull_events(request, nil)

      assert result.total_count == 2
    end

    test "returns correct next_offset events", %{topic: topic} do
      totals = [10, 30, 54, 23, 22, 65, 14, 56]

      Enum.each(totals, fn total ->
        attrs = params_for(:event, topic: topic)
        attrs = %{attrs | data: %{"cart" => %{"total" => total}}}
        ER.Events.create_event_for_topic(attrs)
      end)

      request = %PullEventsRequest{
        topic: topic.name,
        filters: [],
        batch_size: 3,
        offset: 0
      }

      result = Server.pull_events(request, nil)

      assert result.next_offset == 3
      assert result.previous_offset == nil

      request = %PullEventsRequest{
        topic: topic.name,
        filters: [],
        batch_size: 3,
        offset: result.next_offset
      }

      result = Server.pull_events(request, nil)

      assert result.next_offset == 6
      assert result.previous_offset == 0

      request = %PullEventsRequest{
        topic: topic.name,
        filters: [],
        batch_size: 3,
        offset: result.next_offset
      }

      result = Server.pull_events(request, nil)

      assert result.next_offset == nil
      assert result.previous_offset == 3
    end

    test "returns filtered events", %{topic: topic} do
      totals = [10, 30]

      Enum.each(totals, fn total ->
        attrs = params_for(:event, topic: topic)
        attrs = %{attrs | data: %{"cart" => %{"total" => total}}}
        ER.Events.create_event_for_topic(attrs)
      end)

      request = %PullEventsRequest{
        topic: topic.name,
        filters: [
          %Filter{
            field_path: "data.cart.total",
            comparison: "equal",
            cast_as: :INTEGER,
            value: "30"
          }
        ]
      }

      result = Server.pull_events(request, nil)

      assert result.total_count == 1
    end
  end
end
