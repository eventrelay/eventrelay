defmodule ER.Destinations.Push.WebsocketDestination do
  defstruct destination: nil
end

defimpl ER.Destinations.Push.Destination, for: ER.Destinations.Push.WebsocketDestination do
  require Logger
  alias ER.Events.Event
  alias ER.Destinations.Push.WebsocketDestination

  def push(
        %WebsocketDestination{destination: %{paused: false} = destination},
        %Event{} = event
      ) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(destination)}, #{inspect(event)}) on node=#{inspect(Node.self())}"
    )

    if ER.Container.channel_cache().any_sockets?(destination.id) do
      ERWeb.Endpoint.broadcast("events:#{destination.id}", "event:published", event)
    else
      Logger.debug(
        "#{__MODULE__}.push(#{inspect(destination)}, #{inspect(event)}) do not push because there are no sockets connected on node=#{inspect(Node.self())}"
      )
    end
  end

  def push(
        %WebsocketDestination{destination: destination},
        %Event{} = event
      ) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(destination)}, #{inspect(event)}) do not push on node=#{inspect(Node.self())}"
    )
  end
end
