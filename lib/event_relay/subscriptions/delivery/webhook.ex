defmodule ER.Subscriptions.Delivery.Webhook do
  require Logger
  alias ER.Subscriptions.Subscription
  alias ER.Events.Event

  def push(%Subscription{} = subscription, %Event{} = event) do
    Logger.debug("Pushing event to webhook #{inspect(subscription)}")
    topic_name = subscription.topic_name

    delivery = ER.Subscriptions.build_delivery_for_topic(topic_name)
    Logger.debug("Created delivery #{inspect(delivery)}")

    ER.Subscriptions.Delivery.Server.factory(delivery.id, %{
      "topic_name" => topic_name,
      "delivery" => delivery,
      "subscription" => subscription,
      "event" => event
    })
  end
end
