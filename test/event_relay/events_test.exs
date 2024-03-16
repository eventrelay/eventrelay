defmodule ER.EventsTest do
  use ER.DataCase
  use Mimic

  alias ER.Events
  import ER.Factory
  import ExUnit.CaptureLog

  describe "delete_events_for_topic_before/3" do
    setup do
      {:ok, topic} = ER.Events.create_topic(%{name: "metrics"})

      max_age = 900

      pruner =
        insert(:pruner,
          topic: topic,
          query: "group_key == 'target_group'",
          config: %{"max_age" => max_age},
          type: :time
        )

      {:ok, topic: topic, pruner: pruner, max_age: max_age}
    end

    test "deletes events that are older than the max_age and that match the query filter", %{
      topic: topic,
      pruner: %{query: query, config: %{"max_age" => max_age}}
    } do
      datetime = DateTime.utc_now()

      before = DateTime.add(datetime, max_age * -1, :second)

      occurred_at_to_prune =
        DateTime.add(datetime, (max_age + 600) * -1, :second) |> DateTime.to_iso8601()

      # event to delete
      attrs =
        params_for(:event,
          topic: topic,
          name: "user.updated",
          group_key: "target_group",
          source: "app",
          offset: 1,
          occurred_at: occurred_at_to_prune,
          data: %{"first_name" => "Thomas"}
        )

      Events.create_event_for_topic(attrs)

      # event to keep
      attrs =
        params_for(:event,
          topic: topic,
          name: "user.created",
          source: "app",
          group_key: "not_target_group",
          offset: 2,
          occurred_at: occurred_at_to_prune,
          data: %{"first_name" => "Thomas"}
        )

      {:ok, to_keep_1} = Events.create_event_for_topic(attrs)

      # event to keep
      attrs =
        params_for(:event,
          topic: topic,
          name: "user.updated",
          group_key: "target_group",
          source: "grpc",
          offset: 3,
          occurred_at: DateTime.to_iso8601(datetime),
          data: %{"first_name" => "Thomas"}
        )

      {:ok, to_keep_2} = Events.create_event_for_topic(attrs)

      {deleted_count, _} = Events.delete_events_for_topic_before(topic.name, before, query)
      assert deleted_count == 1

      events =
        Events.list_events_for_topic(topic.name, topic_identifier: nil, return_batch: false)

      assert Enum.map(events, & &1.id) == [to_keep_1.id, to_keep_2.id]
    end
  end

  describe "delete_events_for_topic_over/3" do
    setup do
      {:ok, topic} = ER.Events.create_topic(%{name: "metrics"})

      max_count = 1

      pruner =
        insert(:pruner,
          topic: topic,
          query: "group_key == 'target_group'",
          config: %{"max_count" => max_count},
          type: :count
        )

      {:ok, topic: topic, pruner: pruner}
    end

    test "deletes events that are not the newest x events and that match the query filter", %{
      topic: topic,
      pruner: %{query: query, config: %{"max_count" => max_count}}
    } do
      datetime = DateTime.utc_now()

      # event to keep
      attrs =
        params_for(:event,
          topic: topic,
          name: "user.updated",
          group_key: "target_group",
          source: "app",
          offset: 1,
          occurred_at: DateTime.add(datetime, 600 * -1, :second) |> DateTime.to_iso8601(),
          data: %{"first_name" => "Thomas"}
        )

      {:ok, to_keep_1} = Events.create_event_for_topic(attrs)

      # event to keep
      attrs =
        params_for(:event,
          topic: topic,
          name: "user.created",
          source: "app",
          group_key: "not_target_group",
          offset: 2,
          occurred_at: DateTime.add(datetime, 600 * -1, :second) |> DateTime.to_iso8601(),
          data: %{"first_name" => "Thomas"}
        )

      {:ok, to_keep_2} = Events.create_event_for_topic(attrs)

      # event to delete
      attrs =
        params_for(:event,
          topic: topic,
          name: "user.updated",
          group_key: "target_group",
          source: "grpc",
          offset: 3,
          occurred_at: DateTime.add(datetime, 800 * -1, :second) |> DateTime.to_iso8601(),
          data: %{"first_name" => "Thomas"}
        )

      {:ok, _event} = Events.create_event_for_topic(attrs)

      {deleted_count, _} = Events.delete_events_for_topic_over(topic.name, max_count, query)
      assert deleted_count == 1

      events =
        Events.list_events_for_topic(topic.name, topic_identifier: nil, return_batch: false)

      assert Enum.map(events, & &1.id) == [to_keep_1.id, to_keep_2.id]
    end
  end

  describe "list_events_for_topic/1" do
    setup do
      {:ok, topic} = ER.Events.create_topic(%{name: "Metrics"})

      {:ok, topic: topic}
    end

    test "returns events", %{
      topic: topic
    } do
      attrs =
        params_for(:event,
          topic: topic,
          name: "user.updated",
          source: "app",
          offset: 1,
          data: %{"first_name" => "Thomas"}
        )

      Events.create_event_for_topic(attrs)

      attrs =
        params_for(:event,
          topic: topic,
          name: "user.created",
          source: "app",
          offset: 2,
          data: %{"first_name" => "Thomas"}
        )

      Events.create_event_for_topic(attrs)

      # this event should not be returned
      attrs =
        params_for(:event,
          topic: topic,
          name: "user.created",
          source: "app",
          offset: 2,
          data: %{"first_name" => "Thomas"},
          available_at: ~U[3000-12-21 18:27:00Z]
        )

      Events.create_event_for_topic(attrs)

      attrs =
        params_for(:event,
          topic: topic,
          name: "user.updated",
          source: "grpc",
          offset: 3,
          data: %{"first_name" => "Thomas"}
        )

      Events.create_event_for_topic(attrs)

      {:ok, predicates} =
        Predicated.Query.new(
          "data.first_name == 'Thomas' AND (source == 'grpc' OR name == 'user.created')"
        )

      batch =
        Events.list_events_for_topic(
          topic.name,
          offset: 0,
          batch_size: 10,
          topic_identifier: nil,
          predicates: predicates
        )

      assert Enum.count(batch.results) == 2
    end
  end

  describe "list_queued_events_for_topic/1" do
    setup do
      {:ok, topic} = ER.Events.create_topic(%{name: "jobs"})
      destination = insert(:destination, topic: topic)
      destination_with_locks = insert(:destination, topic: topic)

      {:ok,
       topic: topic, destination: destination, destination_with_locks: destination_with_locks}
    end

    test "returns events that respect the destination_locks", %{
      topic: topic,
      destination: destination,
      destination_with_locks: destination_with_locks
    } do
      lock_events =
        Enum.map(1..9, fn i ->
          attrs =
            params_for(:event,
              topic: topic,
              offset: i,
              destination_locks: [destination_with_locks.id]
            )

          Events.create_event_for_topic(attrs)
        end)

      _unlock_events =
        Enum.map(10..19, fn i ->
          Events.create_event_for_topic(params_for(:event, topic: topic, offset: i))
        end)

      # should not show in results
      Events.create_event_for_topic(
        params_for(:event,
          topic: topic,
          offset: 1000,
          available_at: ~U[3000-12-21 18:27:00Z]
        )
      )

      # first lets attempt to get events for destination that have some events locked
      events =
        Events.list_queued_events_for_topic(
          batch_size: 100,
          destination: destination_with_locks
        )

      assert Enum.count(events) == 10
      first_event = List.first(events)

      # this would be the first locked event
      refute first_event.offset == 1

      # ensure that our first event is the first non-locked event
      assert first_event.offset == 10

      events =
        Events.list_queued_events_for_topic(
          batch_size: 100,
          destination: destination
        )

      # should return all events
      assert Enum.count(events) == 19
      first_event = List.first(events)
      assert first_event.offset == 1

      # lets unlock an event and query again
      {:ok, last_locked_event} = List.last(lock_events)

      last_locked_event
      |> Events.change_event(%{destination_locks: []})
      |> Repo.update()

      events =
        Events.list_queued_events_for_topic(
          batch_size: 100,
          destination: destination_with_locks
        )

      # we should have the original 10 plus the unlocked event
      assert Enum.count(events) == 11
      event = List.first(events)
      # check that the first event is the last offset of the locked events
      assert event.offset == 9

      Events.lock_destination_events(destination.id, events)
    end
  end

  describe "lock_destination_events/2" do
    setup do
      {:ok, topic} = ER.Events.create_topic(%{name: "jobs"})
      destination = insert(:destination, topic: topic)

      {:ok, topic: topic, destination: destination}
    end

    test "locks the events for that destination", %{
      topic: topic,
      destination: destination
    } do
      unlocked_events =
        Enum.map(1..10, fn i ->
          attrs =
            params_for(:event,
              topic: topic,
              offset: i
            )

          {:ok, event} = Events.create_event_for_topic(attrs)
          event
        end)

      Events.lock_destination_events(destination.id, unlocked_events)

      events =
        Events.list_queued_events_for_topic(
          batch_size: 100,
          destination: destination
        )

      # now that all the events are locked non should be found
      assert events == []
    end
  end

  describe "events" do
    alias ER.Events.Event

    @invalid_attrs %{
      context: nil,
      data: nil,
      name: nil,
      occurred_at: nil,
      offset: nil,
      source: nil
    }

    test "list_events/0 returns all events" do
      event = insert(:event)
      assert Events.list_events() == [event]
    end

    test "list_events/1 returns all events for topic, offset and batch_size" do
      event = insert(:event)
      assert Events.list_events() == [event]
    end

    test "get_event!/1 returns the event with given id" do
      event = insert(:event)
      assert Events.get_event!(event.id) == event
    end

    test "create_event_for_topic/1 with invalid data creates a event in the dead letter events table" do
      event = %{
        context: %{},
        data: %{},
        name: "some name",
        occurred_at: DateTime.to_iso8601(~U[2022-12-21 18:27:00Z]),
        source: "some source",
        topic_name: "albums"
      }

      assert capture_log(fn ->
               assert {:error, event} = Events.create_event_for_topic(event)

               assert Ecto.get_meta(event, :source) ==
                        "dead_letter_events"

               assert event.errors == ["relation \"albums_events\" does not exist"]
             end) =~ "relation \"albums_events\" does not exist"
    end

    test "create_event_for_topic/1 with no data creates a event in the dead letter events table" do
      topic = insert(:topic)
      ER.Events.Event.create_table!(topic)

      event = %{
        context: %{},
        data: nil,
        name: "some name",
        occurred_at: DateTime.to_iso8601(~U[2022-12-21 18:27:00Z]),
        source: "some source",
        topic_name: topic.name
      }

      assert capture_log(fn ->
               assert {:error, event} = Events.create_event_for_topic(event)

               assert Ecto.get_meta(event, :source) ==
                        "dead_letter_events"

               assert event.errors == ["Data can't be blank"]
             end) =~ "can't be blank"

      ER.Events.Event.drop_table!(topic)
    end

    test "create_event_for_topic/1 with valid data creates a event in the proper topic events table" do
      topic = insert(:topic, name: "test")
      ER.Events.Event.create_table!(topic)
      occurred_at = DateTime.to_iso8601(~U[2022-12-21 18:27:00Z])
      available_at = DateTime.to_iso8601(~U[2021-12-21 18:27:00Z])

      event = %{
        context: %{},
        data: %{},
        name: "some name",
        occurred_at: occurred_at,
        available_at: available_at,
        source: "some source",
        topic_name: topic.name
      }

      assert {:ok, %Event{} = event} = Events.create_event_for_topic(event)

      assert Flamel.Moment.to_iso8601(event.occurred_at) == occurred_at
      assert Flamel.Moment.to_iso8601(event.available_at) == available_at

      assert Ecto.get_meta(event, :source) ==
               "test_events"

      ER.Events.Event.drop_table!(topic)
    end

    test "create_event_for_topic/1 and set a default occurred_at and available_at " do
      topic = insert(:topic, name: "test")
      ER.Events.Event.create_table!(topic)

      event = %{
        context: %{},
        data: %{},
        name: "some name",
        source: "some source",
        topic_name: topic.name
      }

      assert {:ok, %Event{} = event} = Events.create_event_for_topic(event)

      refute event.occurred_at == nil
      refute event.available_at == nil

      assert Ecto.get_meta(event, :source) ==
               "test_events"

      ER.Events.Event.drop_table!(topic)
    end

    test "create_event_for_topic/1 with data that is invalid according to the event data_schema creates a event in the dead letter events table" do
      topic = insert(:topic, name: "test")
      ER.Events.Event.create_table!(topic)

      event = %{
        context: %{},
        data: %{
          "first_name" => 123
        },
        data_schema: %{
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
        },
        name: "some name",
        occurred_at: DateTime.to_iso8601(~U[2022-12-21 18:27:00Z]),
        source: "some source",
        topic_name: topic.name
      }

      assert capture_log(fn ->
               assert {:error, event} = Events.create_event_for_topic(event)

               assert Ecto.get_meta(event, :source) ==
                        "dead_letter_events"
             end) =~ "Invalid changeset for event"

      ER.Events.Event.drop_table!(topic)
    end

    test "produce_event_for_topic/1 with valid data publishes an event" do
      topic = insert(:topic, name: "test")
      ER.Events.Event.create_table!(topic)
      occurred_at = DateTime.to_iso8601(~U[2022-12-21 18:27:00Z])
      available_at = DateTime.to_iso8601(~U[2021-12-21 18:27:00Z])

      destination = insert(:destination, destination_type: :websocket, topic: topic)

      event = %{
        context: %{},
        data: %{},
        name: "my.unique.event",
        occurred_at: occurred_at,
        available_at: available_at,
        source: "some source",
        topic_name: topic.name
      }

      ER.Events.ChannelCache
      |> expect(:any_sockets?, fn destination_id ->
        assert destination_id == destination.id

        true
      end)

      ERWeb.Endpoint
      |> expect(:broadcast, fn topic, event_name, message ->
        assert topic == "events:#{destination.id}"
        assert event_name == "event:published"
        assert message.name == "my.unique.event"
      end)

      assert {:ok, %Event{} = event} = Events.produce_event_for_topic(event)

      assert Flamel.Moment.to_iso8601(event.occurred_at) == occurred_at
      assert Flamel.Moment.to_iso8601(event.available_at) == available_at

      assert Ecto.get_meta(event, :source) ==
               "test_events"

      ER.Events.Event.drop_table!(topic)
    end

    test "produce_event_for_topic/1 with valid data per the event schema publishes an event" do
      schema = ~S"""
      {"$schema":"http://json-schema.org/draft-04/schema#","description":"Stores data about a page that is visited","properties":{"height":{"description":"","type":"string"},"path":{"description":"","type":"string"},"search":{"description":"","type":"string"},"title":{"description":"","type":"string"},"url":{"description":"","type":"string"},"width":{"description":"","type":"string"}},"title":"Page Event","type":"object", "required": ["title", "url"]}
      """

      ER.Events.TopicCache
      |> expect(:fetch_event_schema_for_topic_and_event, fn _, _ ->
        nil
      end)

      event_configs = [%ER.Events.EventConfig{name: "analytics.page", schema: schema}]
      topic = insert(:topic, name: "test", event_configs: event_configs)

      ER.Events.Event.create_table!(topic)
      occurred_at = DateTime.to_iso8601(~U[2022-12-21 18:27:00Z])
      available_at = DateTime.to_iso8601(~U[2021-12-21 18:27:00Z])

      destination = insert(:destination, destination_type: :websocket, topic: topic)

      event = %{
        context: %{},
        data: %{title: "test", url: "https://example.com"},
        name: "analytics.page",
        occurred_at: occurred_at,
        available_at: available_at,
        source: "some source",
        topic_name: topic.name
      }

      ER.Events.ChannelCache
      |> expect(:any_sockets?, fn destination_id ->
        assert destination_id == destination.id

        true
      end)

      assert {:ok, %Event{} = event} = Events.produce_event_for_topic(event)

      assert Flamel.Moment.to_iso8601(event.occurred_at) == occurred_at
      assert Flamel.Moment.to_iso8601(event.available_at) == available_at

      assert Ecto.get_meta(event, :source) ==
               "test_events"

      ER.Events.Event.drop_table!(topic)
    end

    test "produce_event_for_topic/1 with invalid data per the event schema does not publishes an event" do
      schema =
        ~S"""
        {"$schema":"http://json-schema.org/draft-04/schema#","description":"Stores data about a page that is visited","properties":{"height":{"description":"","type":"string"},"path":{"description":"","type":"string"},"search":{"description":"","type":"string"},"title":{"description":"","type":"string"},"url":{"description":"","type":"string"},"width":{"description":"","type":"string"}},"title":"Page Event","type":"object", "required": ["path"]}
        """
        |> String.trim()

      event_configs = [%ER.Events.EventConfig{name: "analytics.page", schema: schema}]
      topic = insert(:topic, name: "test", event_configs: event_configs)

      ER.Events.Event.create_table!(topic)
      occurred_at = DateTime.to_iso8601(~U[2022-12-21 18:27:00Z])
      available_at = DateTime.to_iso8601(~U[2021-12-21 18:27:00Z])

      event = %{
        context: %{},
        data: %{ugh: "test", url: "https://example.com"},
        name: "analytics.page",
        occurred_at: occurred_at,
        available_at: available_at,
        source: "some source",
        topic_name: topic.name,
      }

      assert capture_log(fn ->
               assert {:error, event} = Events.produce_event_for_topic(event)

               assert event.errors == [
                        "Data does not validate against the schema because of errors: Required property path was not present."
                      ]
             end) =~ "Invalid changeset for event"

      ER.Events.Event.drop_table!(topic)
    end

    test "update_event/2 with valid data updates the event" do
      event = insert(:event)
      topic = insert(:topic)

      update_attrs = %{
        context: %{},
        data: %{},
        name: "some updated name",
        occurred_at: DateTime.to_iso8601(~U[2022-12-21 18:27:00Z]),
        source: "some updated source",
        topic_name: topic.name
      }

      assert {:ok, %Event{} = event} = Events.update_event(event, update_attrs)
      assert event.context == %{}
      assert event.data == %{}
      assert event.name == "some updated name"
      assert event.occurred_at == ~U[2022-12-21 18:27:00Z]
      refute event.offset == nil
      assert event.source == "some updated source"
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = insert(:event)
      assert {:error, %Ecto.Changeset{}} = Events.update_event(event, @invalid_attrs)
      assert event == Events.get_event!(event.id)
    end

    test "delete_event/1 deletes the event" do
      event = insert(:event)
      assert {:ok, %Event{}} = Events.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Events.get_event!(event.id) end
    end

    test "delete_events_for_topic!/1 deletes the event" do
      topic = insert(:topic, name: "test")
      ER.Events.Event.create_table!(topic)
      ER.Events.create_event_for_topic(params_for(:event, topic: topic))
      ER.Events.create_event_for_topic(params_for(:event, topic: topic))

      %ER.BatchedResults{
        results: results,
        offset: 0,
        batch_size: 100,
        next_offset: nil,
        previous_offset: nil,
        total_count: 2,
        total_batches: 1
      } =
        Events.list_events_for_topic(
          topic.name,
          offset: 0,
          batch_size: 100,
          topic_identifier: nil
        )

      assert length(results) == 2

      Events.delete_events_for_topic!(topic)

      assert %ER.BatchedResults{
               results: [],
               offset: 0,
               batch_size: 100,
               next_offset: nil,
               previous_offset: nil,
               total_count: 0,
               total_batches: 0
             } ==
               Events.list_events_for_topic(
                 topic.name,
                 offset: 0,
                 batch_size: 100,
                 topic_identifier: nil
               )
    end

    test "change_event/1 returns a event changeset" do
      event = insert(:event)
      assert %Ecto.Changeset{} = Events.change_event(event)
    end
  end

  describe "topics" do
    alias ER.Events.Topic
    alias ER.Events.Event

    @invalid_attrs %{name: nil}

    test "list_topics/0 returns all topics" do
      topic = insert(:topic)
      assert Events.list_topics() == [topic]
    end

    test "get_topic!/1 returns the topic with given id" do
      topic = insert(:topic)
      assert Events.get_topic!(topic.id) == topic
    end

    test "create_topic/1 with valid data creates a topic" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Topic{} = topic} = Events.create_topic(valid_attrs)
      assert topic.name == "some_name"
    end

    test "create_topic/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_topic(@invalid_attrs)
    end

    test "create_topic_and_table/1 with valid data creates a topic" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Topic{} = topic} = Events.create_topic(valid_attrs)
      assert topic.name == "some_name"

      event = %{
        context: %{},
        data: %{},
        name: "some name",
        occurred_at: DateTime.to_iso8601(~U[2022-12-21 18:27:00Z]),
        source: "some source",
        topic_name: topic.name
      }

      assert {:ok, %Event{}} = Events.create_event_for_topic(event)
    end

    test "create_topic_and_table/1 with invalid data creates a topic" do
      valid_attrs = %{name: "this_is_a_really_long_name_that_is_too_long_that_is_way_too_long"}

      {:error, changeset} = Events.create_topic(valid_attrs)

      assert changeset.errors == [
               name:
                 {"should be at most %{count} character(s)",
                  [count: 45, validation: :length, kind: :max, type: :string]}
             ]
    end

    test "update_topic/2 with valid data updates the topic" do
      topic = insert(:topic)
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Topic{} = topic} = Events.update_topic(topic, update_attrs)
      assert topic.name == "some_updated_name"
    end

    test "update_topic/2 with invalid data returns error changeset" do
      topic = insert(:topic)
      assert {:error, %Ecto.Changeset{}} = Events.update_topic(topic, @invalid_attrs)
      assert topic == Events.get_topic!(topic.id)
    end

    test "delete_topic/1 deletes the topic" do
      {:ok, topic} = Events.create_topic(%{name: "test"})
      assert {:ok, %Topic{}} = Events.delete_topic(topic)
      assert_raise Ecto.NoResultsError, fn -> Events.get_topic!(topic.id) end
    end

    test "change_topic/1 returns a topic changeset" do
      topic = insert(:topic)
      assert %Ecto.Changeset{} = Events.change_topic(topic)
    end
  end
end
