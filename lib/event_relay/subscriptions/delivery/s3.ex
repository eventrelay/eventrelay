defmodule ER.Subscriptions.Delivery.S3 do
  require Logger
  alias ER.Subscriptions
  alias ER.Subscriptions.Subscription
  alias ER.Events.Event

  def push(%Subscription{} = subscription, %Event{} = event) do
    Logger.debug(
      "#{__MODULE__}.push_event(#{inspect(subscription)}, #{inspect(event)}) on node=#{inspect(Node.self())}"
    )

    Subscriptions.create_delivery_for_topic(
      event.topic.name,
      %{status: :pending, event_id: event.id, subscription_id: subscription.id}
    )
  end
end
