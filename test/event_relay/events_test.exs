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

    import ER.EventsFixtures

    @invalid_attrs %{name: nil}

    test "list_topics/0 returns all topics" do
      topic = topic_fixture()
      assert Events.list_topics() == [topic]
    end

    test "get_topic!/1 returns the topic with given id" do
      topic = topic_fixture()
      assert Events.get_topic!(topic.id) == topic
    end

    test "create_topic/1 with valid data creates a topic" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Topic{} = topic} = Events.create_topic(valid_attrs)
      assert topic.name == "some name"
    end

    test "create_topic/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_topic(@invalid_attrs)
    end

    test "update_topic/2 with valid data updates the topic" do
      topic = topic_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Topic{} = topic} = Events.update_topic(topic, update_attrs)
      assert topic.name == "some updated name"
    end

    test "update_topic/2 with invalid data returns error changeset" do
      topic = topic_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_topic(topic, @invalid_attrs)
      assert topic == Events.get_topic!(topic.id)
    end

    test "delete_topic/1 deletes the topic" do
      topic = topic_fixture()
      assert {:ok, %Topic{}} = Events.delete_topic(topic)
      assert_raise Ecto.NoResultsError, fn -> Events.get_topic!(topic.id) end
    end

    test "change_topic/1 returns a topic changeset" do
      topic = topic_fixture()
      assert %Ecto.Changeset{} = Events.change_topic(topic)
    end
  end
end
