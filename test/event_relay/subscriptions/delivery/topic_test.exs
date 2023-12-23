defmodule ER.Subscriptions.Delivery.TopicTest do
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

    subscription =
      insert(:subscription,
        subscription_type: :topic,
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

    {:ok, subscription: subscription, event: event, to_topic: to_topic, from_topic: from_topic}
  end

  describe "push/2" do
    test "creates a new event in a different topic", %{
      subscription: subscription,
      event: old_event,
      to_topic: to_topic,
      from_topic: from_topic
    } do
      push_subscription = ER.Subscriptions.Push.Factory.build(subscription)
      {:ok, new_event} = ER.Subscriptions.Push.Subscription.push(push_subscription, old_event)

      refute new_event.topic_name == from_topic.name
      assert new_event.topic_name == to_topic.name
      assert new_event.data == old_event.data
      assert new_event.context == old_event.context
      assert new_event.subscription_locks == []
    end
  end
end
