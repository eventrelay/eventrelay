defmodule ER.Subscriptions.Delivery.Webhook do
  require Logger
  alias ER.Subscriptions.Subscription
  alias ER.Events.Event

  def push(%Subscription{} = subscription, %Event{} = event) do
    Logger.debug("Pushing event to webhook #{inspect(subscription)}")
    topic_name = subscription.topic_name

    case ER.Subscriptions.create_delivery_for_topic(topic_name, %{
           subscription_id: subscription.id,
           event_id: event.id
         }) do
      {:ok, delivery} ->
        Logger.debug("Created delivery #{inspect(delivery)}")

        ER.Subscriptions.Delivery.Server.factory(delivery.id, %{
          "topic_name" => topic_name
        })

      {:error, changeset} ->
        Logger.error("Failed to create delivery: #{inspect(changeset)}")
    end
  end
end
