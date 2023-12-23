defmodule ER.Subscriptions.Push.WebsocketSubscription do
  defstruct subscription: nil
end

defimpl ER.Subscriptions.Push.Subscription, for: ER.Subscriptions.Push.WebsocketSubscription do
  require Logger
  alias ER.Events.Event
  alias ER.Subscriptions.Push.WebsocketSubscription

  def push(%WebsocketSubscription{subscription: subscription}, %Event{} = event) do
    Logger.debug(
      "#{__MODULE__}.push_event(#{inspect(subscription)}, #{inspect(event)}) on node=#{inspect(Node.self())}"
    )

    ERWeb.Endpoint.broadcast("events:#{subscription.id}", "event:published", event)
  end
end
