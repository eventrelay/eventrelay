defmodule ER.Destinations.Pipeline.TopicTest do
  use ER.DataCase
  alias ER.Events.Event
  alias ER.Events
  alias ER.Repo

  import ER.Factory

  setup do
    from_topic = insert(:topic, name: "from")
    Event.create_table!(from_topic)
    to_topic = insert(:topic, name: "to")
    Event.create_table!(to_topic)

    context = %{"" => ""}
    data = %{"" => ""}

    destination =
      insert(:destination,
        destination_type: :topic,
        topic: from_topic,
        config: %{"topic_name" => to_topic.name}
      )

    event_params = params_for(:event, topic_name: from_topic.name, data: data, context: context)

    {:ok, event} = Events.create_event_for_topic(event_params)
    event = Repo.preload(event, :topic)

    on_exit(fn ->
      Event.drop_table!(from_topic)
      Event.drop_table!(to_topic)
    end)

    {:ok, destination: destination, event: event, to_topic: to_topic, from_topic: from_topic}
  end

  describe "forward/2" do
    test "creates a new event in a different topic", %{
      event: old_event,
      to_topic: to_topic,
      from_topic: from_topic,
      destination: destination
    } do
      {:ok, new_event} = ER.Destinations.Topic.forward(to_topic.name, old_event, destination)

      refute new_event.topic_name == from_topic.name
      assert new_event.topic_name == to_topic.name
      assert new_event.data == old_event.data
      assert new_event.context == old_event.context
      assert new_event.group_key == old_event.group_key
      assert new_event.user_key == old_event.user_key
      assert new_event.reference_key == old_event.reference_key
      assert new_event.trace_key == old_event.trace_key
      assert new_event.destination_locks == []
    end

    test "creates a new event in a different topic that has been transformed", %{
      event: old_event,
      to_topic: to_topic,
      from_topic: from_topic,
      destination: destination
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
        destination: destination,
        return_type: :map,
        query: "name == '#{old_event.name}'"
      )

      {:ok, new_event} = ER.Destinations.Topic.forward(to_topic.name, old_event, destination)

      refute new_event.topic_name == from_topic.name
      assert new_event.topic_name == to_topic.name
      assert new_event.data == old_event.data
      assert new_event.context == old_event.context
      assert new_event.destination_locks == []
      assert new_event.source == "internal"
      assert new_event.name == "another.name"
      assert old_event.group_key == "org123"
      assert new_event.group_key == nil
    end

    test "creates a new event if the prev_id is empty", %{
      event: old_event,
      to_topic: to_topic,
      from_topic: from_topic,
      destination: destination
    } do
      {:ok, new_event} = ER.Destinations.Topic.forward(to_topic.name, old_event, destination)

      refute new_event.topic_name == from_topic.name
      assert new_event.topic_name == to_topic.name
      assert new_event.data == old_event.data
      assert new_event.context == old_event.context
      assert new_event.destination_locks == []
    end
  end
end
