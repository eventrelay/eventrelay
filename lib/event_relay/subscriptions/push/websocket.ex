defmodule ER.Subscriptions.Push.WebsocketSubscription do
  defstruct subscription: nil
end

defimpl ER.Subscriptions.Push.Subscription, for: ER.Subscriptions.Push.WebsocketSubscription do
  require Logger
  alias ER.Events.Event
  alias ER.Subscriptions.Push.WebsocketSubscription

  def push(
        %WebsocketSubscription{subscription: %{paused: false} = subscription},
        %Event{} = event
      ) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(subscription)}, #{inspect(event)}) on node=#{inspect(Node.self())}"
    )

    if ER.Container.channel_cache().any_sockets?(subscription.id) do
      ERWeb.Endpoint.broadcast("events:#{subscription.id}", "event:published", event)
    else
      Logger.debug(
        "#{__MODULE__}.push(#{inspect(subscription)}, #{inspect(event)}) do not push because there are no sockets connected on node=#{inspect(Node.self())}"
      )
    end
  end

  def push(
        %WebsocketSubscription{subscription: subscription},
        %Event{} = event
      ) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(subscription)}, #{inspect(event)}) do not push on node=#{inspect(Node.self())}"
    )
  end
end
