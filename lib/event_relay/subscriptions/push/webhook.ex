defmodule ER.Subscriptions.Push.WebhookSubscription do
  defstruct subscription: nil
end

defimpl ER.Subscriptions.Push.Subscription, for: ER.Subscriptions.Push.WebhookSubscription do
  require Logger
  alias ER.Events.Event
  alias ER.Subscriptions.Push.WebhookSubscription

  def push(%WebhookSubscription{subscription: %{paused: false} = subscription}, %Event{} = event) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(subscription)}, #{inspect(event)}) on node=#{inspect(Node.self())}"
    )

    topic_name = subscription.topic_name

    delivery = ER.Subscriptions.build_delivery_for_topic(topic_name)
    Logger.debug("Created delivery #{inspect(delivery)}")

    ER.Subscriptions.Webhook.Delivery.Server.factory(delivery.id, %{
      "topic_name" => topic_name,
      "delivery" => delivery,
      "subscription" => subscription,
      "event" => event
    })
  end

  def push(%WebhookSubscription{subscription: subscription}, %Event{} = event) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(subscription)}, #{inspect(event)}) do not push on node=#{inspect(Node.self())}"
    )
  end
end
