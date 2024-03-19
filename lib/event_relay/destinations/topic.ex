defmodule ER.Destinations.Topic do
  @moduledoc """
  Handles taking an existing event and forwarding it to a new topic
  """

  alias ER.Events.Event
  alias ER.Destinations.Destination

  def forward(topic_name, event, destination) do
    event
    |> Event.to_map()
    |> Destination.transform_event(destination)
    |> Map.put(:topic_name, topic_name)
    |> Map.put(:prev_id, event.id)
    |> ER.Events.produce_event_for_topic()
  end
end
