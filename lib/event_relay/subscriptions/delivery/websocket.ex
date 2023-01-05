defmodule ER.Subscriptions.Delivery.Websocket do
  require Logger
  alias ER.Subscriptions.Subscription
  alias ER.Events.Event

  def push(%Subscription{} = subscription, %Event{} = event) do
    Logger.debug(
      "#{__MODULE__}.push_event(#{inspect(subscription)}, #{inspect(event)}) on node=#{inspect(Node.self())}"
    )

    ERWeb.Endpoint.broadcast("events:#{subscription.id}", "event:published", event)
  end
end
