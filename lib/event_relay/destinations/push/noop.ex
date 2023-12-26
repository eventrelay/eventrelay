defmodule ER.Destinations.Push.NoopDestination do
  defstruct destination: nil
end

defimpl ER.Destinations.Push.Destination, for: ER.Destinations.Push.NoopDestination do
  require Logger
  alias ER.Events.Event
  alias ER.Destinations.Push.NoopDestination

  def push(
        %NoopDestination{destination: destination},
        %Event{} = event
      ) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(destination)}, #{inspect(event)}) on node=#{inspect(Node.self())}"
    )
  end
end
