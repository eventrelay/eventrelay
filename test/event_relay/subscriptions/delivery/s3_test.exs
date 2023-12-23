defmodule ER.Subscriptions.Delivery.S3Test do
  use ER.DataCase
  alias ER.Subscriptions.Delivery
  alias ER.Subscriptions.Delivery
  alias ER.Events.Event
  alias ER.Events
  alias ER.Repo

  import ER.Factory

  setup do
    subscription = insert(:subscription, subscription_type: :s3)
    topic = insert(:topic, name: "test")
    Event.create_table!(topic)
    Delivery.create_table!(topic)

    event_params = params_for(:event, topic_name: topic.name)

    {:ok, event} = Events.create_event_for_topic(event_params)
    event = Repo.preload(event, :topic)

    on_exit(fn -> Event.drop_table!(topic) end)

    {:ok, subscription: subscription, event: event}
  end

  describe "push/2" do
    test "creates pending delivery", %{subscription: subscription, event: event} do
      push_subscription = ER.Subscriptions.Push.Factory.build(subscription)
      {:ok, delivery} = ER.Subscriptions.Push.Subscription.push(push_subscription, event)

      assert delivery.status == :pending
      assert delivery.subscription_id == subscription.id
      assert delivery.event_id == event.id
    end
  end
end
