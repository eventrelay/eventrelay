defmodule ER.EventsTest do
  use ER.DataCase

  alias ER.Events
  import ER.Factory

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

    test "create_event/1 with valid data creates a event" do
      topic = insert(:topic)

      valid_attrs = %{
        context: %{},
        data: %{},
        name: "some name",
        occurred_at: ~U[2022-12-21 18:27:00Z],
        source: "some source",
        topic_name: topic.name
      }

      assert {:ok, %Event{} = event} = Events.create_event(valid_attrs)
      assert event.context == %{}
      assert event.data == %{}
      assert event.name == "some name"
      assert event.occurred_at == ~U[2022-12-21 18:27:00Z]
      refute event.offset == nil
      assert event.source == "some source"
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_event(@invalid_attrs)
    end

    test "create_event_for_topic/1 with invalid data creates a event in the dead letter events table" do
      event = %{
        context: %{},
        data: %{},
        name: "some name",
        occurred_at: ~U[2022-12-21 18:27:00Z],
        source: "some source",
        topic_name: "albums"
      }

      assert {:ok, %Event{} = event} = Events.create_event_for_topic(event)

      assert Ecto.get_meta(event, :source) ==
               "dead_letter_events"

      assert event.errors == ["relation \"albums_events\" does not exist"]
    end

    test "create_event_for_topic/1 with no data creates a event in the dead letter events table" do
      topic = insert(:topic)
      ER.Events.Event.create_table!(topic)

      event = %{
        context: %{},
        data: nil,
        name: "some name",
        occurred_at: ~U[2022-12-21 18:27:00Z],
        source: "some source",
        topic_name: topic.name
      }

      assert {:ok, %Event{} = event} = Events.create_event_for_topic(event)

      assert Ecto.get_meta(event, :source) ==
               "dead_letter_events"

      assert event.errors == ["Data can't be blank"]

      ER.Events.Event.drop_table!(topic)
    end

    test "create_event_for_topic/1 with valid data creates a event in the proper topic events table" do
      topic = insert(:topic, name: "test")
      ER.Events.Event.create_table!(topic)

      event = %{
        context: %{},
        data: %{},
        name: "some name",
        occurred_at: ~U[2022-12-21 18:27:00Z],
        source: "some source",
        topic_name: topic.name
      }

      assert {:ok, %Event{} = event} = Events.create_event_for_topic(event)

      assert Ecto.get_meta(event, :source) ==
               "test_events"

      ER.Events.Event.drop_table!(topic)
    end

    test "update_event/2 with valid data updates the event" do
      event = insert(:event)
      topic = insert(:topic)

      update_attrs = %{
        context: %{},
        data: %{},
        name: "some updated name",
        occurred_at: ~U[2022-12-22 18:27:00Z],
        source: "some updated source",
        topic_name: topic.name
      }

      assert {:ok, %Event{} = event} = Events.update_event(event, update_attrs)
      assert event.context == %{}
      assert event.data == %{}
      assert event.name == "some updated name"
      assert event.occurred_at == ~U[2022-12-22 18:27:00Z]
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

      assert {:ok, %Topic{} = topic} = Events.create_topic_and_table(valid_attrs)
      assert topic.name == "some_name"

      event = %{
        context: %{},
        data: %{},
        name: "some name",
        occurred_at: ~U[2022-12-21 18:27:00Z],
        source: "some source",
        topic_name: topic.name
      }

      assert {:ok, %Event{} = event} = Events.create_event_for_topic(event)
    end

    test "create_topic_and_table/1 with invalid data creates a topic" do
      valid_attrs = %{name: "this_is_a_really_long_name_that_is_too_long_that_is_way_too_long"}

      {:error, changeset} = Events.create_topic_and_table(valid_attrs)

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
      topic = insert(:topic)
      assert {:ok, %Topic{}} = Events.delete_topic(topic)
      assert_raise Ecto.NoResultsError, fn -> Events.get_topic!(topic.id) end
    end

    test "change_topic/1 returns a topic changeset" do
      topic = insert(:topic)
      assert %Ecto.Changeset{} = Events.change_topic(topic)
    end
  end
end
