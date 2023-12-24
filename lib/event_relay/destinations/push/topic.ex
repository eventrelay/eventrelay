defmodule ER.Destinations.Push.TopicDestination do
  defstruct destination: nil
end

defimpl ER.Destinations.Push.Destination, for: ER.Destinations.Push.TopicDestination do
  require Logger
  alias ER.Events.Event
  alias ER.Destinations.Push.TopicDestination

  @field_to_drop [:__meta__, :destination_locks, :topic]

  def push(
        %TopicDestination{destination: %{paused: false, config: config} = destination},
        %Event{} = event
      ) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(destination)}, #{inspect(event)}) on node=#{inspect(Node.self())}"
    )

    topic_name = config["topic_name"]

    attrs = Map.from_struct(event)

    attrs =
      attrs
      |> Map.put(:topic_name, topic_name)
      |> Map.drop(@field_to_drop)

    ER.Events.produce_event_for_topic(attrs)
  end

  def push(%TopicDestination{destination: destination}, %Event{} = event) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(destination)}, #{inspect(event)}) do not push on node=#{inspect(Node.self())}"
    )
  end
end
