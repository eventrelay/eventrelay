defmodule ER.Subscriptions.Push.S3Subscription do
  defstruct subscription: nil
end

defimpl ER.Subscriptions.Push.Subscription, for: ER.Subscriptions.Push.S3Subscription do
  require Logger
  alias ER.Subscriptions
  alias ER.Events.Event
  alias ER.Subscriptions.Push.S3Subscription

  def push(%S3Subscription{subscription: subscription}, %Event{} = event) do
    Logger.debug(
      "#{__MODULE__}.push_event(#{inspect(subscription)}, #{inspect(event)}) on node=#{inspect(Node.self())}"
    )

    Subscriptions.create_delivery_for_topic(
      event.topic.name,
      %{status: :pending, event_id: event.id, subscription_id: subscription.id}
    )
  end
end
