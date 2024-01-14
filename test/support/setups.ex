defmodule ER.Test.Setups do
  import ER.Factory

  use ER.DataCase
  alias Broadway.Message
  alias ER.Events

  def setup_topic(_context) do
    topic = insert(:topic)
    ER.Destinations.Delivery.create_table!(topic)
    ER.Events.Event.create_table!(topic)

    on_exit(fn ->
      ER.Destinations.Delivery.drop_table!(topic)
      ER.Events.Event.drop_table!(topic)
    end)

    {:ok, topic: topic}
  end

  def setup_messages(context) do
    topic = context.topic

    {:ok, event} =
      params_for(:event, topic: topic)
      |> Events.create_event_for_topic()

    message = %Message{data: event, acknowledger: Broadway.NoopAcknowledger.init()}

    messages = [message]

    {:ok, event} =
      params_for(:event, topic: topic)
      |> Events.create_event_for_topic()

    message = %Message{data: event, acknowledger: Broadway.NoopAcknowledger.init()}

    messages = [message | messages]

    {:ok, topic: topic, messages: messages}
  end

  def setup_deliveries(context) do
    topic = context.topic

    destination = insert(:destination)

    {:ok, event} = ER.Events.create_event_for_topic(params_for(:event, topic: topic))

    pending_delivery_attrs =
      params_for(:delivery, status: :pending, destination: destination, event: event)

    {:ok, pending_delivery} =
      ER.Destinations.create_delivery_for_topic(topic.name, pending_delivery_attrs)

    {:ok, event_2} = ER.Events.create_event_for_topic(params_for(:event, topic: topic))

    pending_delivery_2_attrs =
      params_for(:delivery, status: :pending, destination: destination, event: event_2)

    {:ok, pending_delivery_2} =
      ER.Destinations.create_delivery_for_topic(topic.name, pending_delivery_2_attrs)

    {:ok, successful_delivery_event} =
      ER.Events.create_event_for_topic(params_for(:event, topic: topic))

    successful_delivery_attrs =
      params_for(:delivery,
        status: :success,
        destination: destination,
        event: successful_delivery_event
      )

    {:ok, successful_delivery} =
      ER.Destinations.create_delivery_for_topic(topic.name, successful_delivery_attrs)

    {:ok, failure_delivery_event} =
      ER.Events.create_event_for_topic(params_for(:event, topic: topic))

    failure_delivery_attrs =
      params_for(:delivery,
        status: :failure,
        destination: destination,
        event: failure_delivery_event
      )

    {:ok, failure_delivery} =
      ER.Destinations.create_delivery_for_topic(topic.name, failure_delivery_attrs)

    {:ok,
     topic: topic,
     destination: destination,
     pending_delivery: pending_delivery,
     pending_delivery_2: pending_delivery_2,
     successful_delivery: successful_delivery,
     failure_delivery: failure_delivery}
  end
end
