defmodule ER.Destinations.Topic do
  @moduledoc """
  Handles taking an existing event and forwarding it to a new topic  
  """

  @field_to_drop [:__meta__, :destination_locks, :topic]

  def forward(topic_name, event) do
    attrs = Map.from_struct(event)

    attrs =
      attrs
      |> Map.put(:topic_name, topic_name)
      |> Map.put(:prev_id, event.id)
      |> Map.drop(@field_to_drop)

    ER.Events.produce_event_for_topic(attrs)
  end
end
