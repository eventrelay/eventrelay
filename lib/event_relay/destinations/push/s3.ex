defmodule ER.Destinations.Push.S3Destination do
  defstruct destination: nil
end

defimpl ER.Destinations.Push.Destination, for: ER.Destinations.Push.S3Destination do
  require Logger
  alias ER.Destinations
  alias ER.Events.Event
  alias ER.Destinations.Push.S3Destination

  def push(%S3Destination{destination: %{paused: false} = destination}, %Event{} = event) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(destination)}, #{inspect(event)}) on node=#{inspect(Node.self())}"
    )

    Destinations.create_delivery_for_topic(
      event.topic.name,
      %{status: :pending, event_id: event.id, destination_id: destination.id}
    )
  end

  def push(%S3Destination{destination: destination}, %Event{} = event) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(destination)}, #{inspect(event)}) do not push on node=#{inspect(Node.self())}"
    )
  end
end
