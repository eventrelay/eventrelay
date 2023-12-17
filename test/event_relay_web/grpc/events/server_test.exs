defmodule ERWeb.Grpc.EventRelay.Events.ServerTest do
  use ER.DataCase

  alias ERWeb.Grpc.EventRelay.Events.Server
  alias ER.Events
  import ER.Factory

  alias ERWeb.Grpc.Eventrelay.{
    PublishEventsRequest,
    NewEvent,
    PullEventsRequest,
    PullQueuedEventsRequest,
    UnLockQueuedEventsRequest
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

    test "publishes events with a data_schema", %{topic: topic} do
      event_name = "entry.created"
      group_key = "groupkey"

      data_schema = %{
        "$schema" => "http://json-schema.org/draft-06/schema#",
        "$id" => "https://eventrelay.org/json-schemas/person",
        "$ref" => "#/definitions/Person",
        "definitions" => %{
          "Person" => %{
            "type" => "object",
            "additionalProperties" => false,
            "properties" => %{
              "first_name" => %{
                "type" => "string"
              }
            },
            "required" => [
              "first_name"
            ],
            "title" => "Person"
          }
        }
      }

      data = %{
        "first_name" => "Jerry"
      }

      request = %PublishEventsRequest{
        topic: topic.name,
        durable: true,
        events: [
          %NewEvent{
            name: event_name,
            data: Jason.encode!(data),
            source: "test",
            group_key: group_key,
            data_schema: Jason.encode!(data_schema)
          }
        ]
      }

      result = Server.publish_events(request, nil)

      [event | _] = result.events

      assert event.name == event_name
      assert event.group_key == group_key
      assert Jason.decode!(event.data) == data
      assert Jason.decode!(event.data_schema) == data_schema

      events = Events.list_events_for_topic(topic_name: topic.name)
      assert Enum.count(events) == 1

      event = List.first(events)

      assert event.name == event_name
      assert event.group_key == group_key
      assert event.data == data
      assert event.data_schema == data_schema
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
        topic: topic.name
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
        batch_size: 3,
        offset: 0
      }

      result = Server.pull_events(request, nil)

      assert result.next_offset == 3
      assert result.previous_offset == nil

      last_offset = result.events |> List.last() |> Map.get(:offset)

      request = %PullEventsRequest{
        topic: topic.name,
        batch_size: 3,
        # 3
        offset: result.next_offset
      }

      result = Server.pull_events(request, nil)

      assert result.next_offset == 6
      assert result.previous_offset == 0

      first_offset = result.events |> List.first() |> Map.get(:offset)

      assert last_offset + 1 == first_offset

      last_offset = result.events |> List.last() |> Map.get(:offset)

      request = %PullEventsRequest{
        topic: topic.name,
        batch_size: 3,
        # 6
        offset: result.next_offset
      }

      result = Server.pull_events(request, nil)

      assert result.next_offset == nil
      assert result.previous_offset == 3

      first_offset = result.events |> List.first() |> Map.get(:offset)

      assert last_offset + 1 == first_offset
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
        query: "data.cart.total == 30"
      }

      result = Server.pull_events(request, nil)

      assert result.total_count == 1
    end
  end

  describe "unlock_queued_events/2" do
    setup do
      {:ok, topic} = Events.create_topic(%{name: "jobs"})
      subscription = insert(:subscription, topic: topic)

      # spin up the subscription servers
      ER.Subscriptions.Server.factory(subscription.id)

      {:ok, subscription: subscription, topic: topic}
    end

    test "unlocks events", %{
      topic: topic,
      subscription: subscription
    } do
      original_events =
        Enum.map(1..10, fn i ->
          attrs =
            params_for(:event,
              topic: topic,
              offset: i
            )

          {:ok, event} = Events.create_event_for_topic(attrs)
          event
        end)

      events_to_unlock = Enum.take(original_events, 2)
      events_to_unlock_ids = Enum.map(events_to_unlock, & &1.id)

      request = %PullQueuedEventsRequest{
        batch_size: 10,
        subscription_id: subscription.id
      }

      result = Server.pull_queued_events(request, nil)

      assert Enum.count(result.events) == 10

      request = %PullQueuedEventsRequest{
        batch_size: 10,
        subscription_id: subscription.id
      }

      result = Server.pull_queued_events(request, nil)

      assert Enum.count(result.events) == 0

      request = %UnLockQueuedEventsRequest{
        subscription_id: subscription.id,
        event_ids: events_to_unlock_ids
      }

      result = Server.unlock_queued_events(request, nil)
      # we should have unlocked two events
      assert Enum.count(result.events) == 2

      request = %PullQueuedEventsRequest{
        batch_size: 10,
        subscription_id: subscription.id
      }

      result = Server.pull_queued_events(request, nil)
      # we should have unlocked two events
      assert Enum.count(result.events) == 2

      request = %PullQueuedEventsRequest{
        batch_size: 10,
        subscription_id: subscription.id
      }

      result = Server.pull_queued_events(request, nil)
      # now we should have 0
      assert Enum.count(result.events) == 0
    end
  end

  describe "pull_queued_events/2" do
    setup do
      {:ok, topic} = Events.create_topic(%{name: "jobs"})
      subscription = insert(:subscription, topic: topic)
      subscription_without_locks = insert(:subscription, topic: topic)

      # spin up the subscription servers
      ER.Subscriptions.Server.factory(subscription.id)
      ER.Subscriptions.Server.factory(subscription_without_locks.id)

      {:ok,
       subscription: subscription,
       subscription_without_locks: subscription_without_locks,
       topic: topic}
    end

    test "returns events", %{
      topic: topic,
      subscription: subscription,
      subscription_without_locks: subscription_without_locks
    } do
      Enum.map(1..20, fn i ->
        attrs =
          params_for(:event,
            topic: topic,
            offset: i
          )

        {:ok, event} = Events.create_event_for_topic(attrs)
        event
      end)

      request = %PullQueuedEventsRequest{
        batch_size: 10,
        subscription_id: subscription.id
      }

      first_result = Server.pull_queued_events(request, nil)

      request = %PullQueuedEventsRequest{
        batch_size: 10,
        subscription_id: subscription.id
      }

      second_result = Server.pull_queued_events(request, nil)

      events = first_result.events
      assert Enum.count(events) == 10
      first_event = List.first(events)
      last_event = List.last(events)
      assert first_event.offset == 1
      assert last_event.offset == 10

      events = second_result.events
      assert Enum.count(events) == 10
      first_event = List.first(events)
      last_event = List.last(events)
      # did we properly sequence the calls and add the locks?
      refute first_event.offset == 1
      refute last_event.offset == 10
      assert first_event.offset == 11
      assert last_event.offset == 20

      # now pull events for a subscription without locks
      request = %PullQueuedEventsRequest{
        batch_size: 10,
        subscription_id: subscription_without_locks.id
      }

      result = Server.pull_queued_events(request, nil)

      events = result.events
      assert Enum.count(events) == 10
      first_event = List.first(events)
      last_event = List.last(events)
      # we should be starting at the beginning again with the subscription that has no locks
      assert first_event.offset == 1
      assert last_event.offset == 10

      request = %PullQueuedEventsRequest{
        batch_size: 10,
        subscription_id: subscription.id
      }

      result = Server.pull_queued_events(request, nil)
      # we should have no results for this subscription since they are all locked
      assert Enum.count(result.events) == 0
    end
  end
end
