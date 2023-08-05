defmodule ER.Test.Setups do
  import ER.Factory

  use ER.DataCase

  def setup_topic(_context) do
    topic = insert(:topic)
    ER.Subscriptions.Delivery.create_table!(topic)
    ER.Events.Event.create_table!(topic)

    on_exit(fn ->
      ER.Subscriptions.Delivery.drop_table!(topic)
      ER.Events.Event.drop_table!(topic)
    end)

    {:ok, topic: topic}
  end

  def setup_deliveries(context) do
    topic = context.topic

    subscription = insert(:subscription)

    {:ok, event} = ER.Events.create_event_for_topic(params_for(:event, topic: topic))

    pending_delivery_attrs =
      params_for(:delivery, status: :pending, subscription: subscription, event: event)

    {:ok, pending_delivery} =
      ER.Subscriptions.create_delivery_for_topic(topic.name, pending_delivery_attrs)

    {:ok, event_2} = ER.Events.create_event_for_topic(params_for(:event, topic: topic))

    pending_delivery_2_attrs =
      params_for(:delivery, status: :pending, subscription: subscription, event: event_2)

    {:ok, pending_delivery_2} =
      ER.Subscriptions.create_delivery_for_topic(topic.name, pending_delivery_2_attrs)

    {:ok, successful_delivery_event} =
      ER.Events.create_event_for_topic(params_for(:event, topic: topic))

    successful_delivery_attrs =
      params_for(:delivery,
        status: :success,
        subscription: subscription,
        event: successful_delivery_event
      )

    {:ok, successful_delivery} =
      ER.Subscriptions.create_delivery_for_topic(topic.name, successful_delivery_attrs)

    {:ok, failure_delivery_event} =
      ER.Events.create_event_for_topic(params_for(:event, topic: topic))

    failure_delivery_attrs =
      params_for(:delivery,
        status: :failure,
        subscription: subscription,
        event: failure_delivery_event
      )

    {:ok, failure_delivery} =
      ER.Subscriptions.create_delivery_for_topic(topic.name, failure_delivery_attrs)

    {:ok,
     topic: topic,
     subscription: subscription,
     pending_delivery: pending_delivery,
     pending_delivery_2: pending_delivery_2,
     successful_delivery: successful_delivery,
     failure_delivery: failure_delivery}
  end
end
