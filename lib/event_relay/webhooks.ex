defmodule ER.Webhooks do
  require Logger

  def push_event(subscription, event) do
    case ER.Subscriptions.create_delivery(%{subscription_id: subscription.id, event_id: event.id}) do
      {:ok, delivery} ->
        Logger.debug("Created delivery #{inspect(delivery)}")
        ER.Subscriptions.Delivery.Server.factory(delivery.id)

      {:error, changeset} ->
        Logger.error("Failed to create delivery: #{inspect(changeset)}")
    end
  end
end
