defmodule ER.Destinations.Topic do
  @moduledoc """
  Handles taking an existing event and forwarding it to a new topic  
  """

  require Logger
  alias ER.Destinations.Destination
  alias ER.Transformers.Transformation
  alias ER.Transformers.TransformationContext

  @field_to_drop [:__meta__, :destination_locks, :topic]

  def forward(topic_name, event, destination) do
    attrs =
      Map.from_struct(event)
      |> Map.drop(@field_to_drop)

    attrs =
      destination
      |> Destination.find_transformer(attrs)
      |> maybe_transform_event(attrs, destination)

    attrs =
      attrs
      |> Map.put(:topic_name, topic_name)
      |> Map.put(:prev_id, event.id)

    ER.Events.produce_event_for_topic(attrs)
  end

  defp maybe_transform_event(nil, attrs, _destination) do
    Logger.debug("#{__MODULE__}.forward no transformer found.")
    attrs
  end

  defp maybe_transform_event(transformer, attrs, destination) do
    transformer
    |> ER.Transformers.factory()
    |> Transformation.perform(
      event: attrs,
      context: TransformationContext.build(destination)
    )
    |> case do
      nil ->
        attrs

      attrs ->
        attrs = Flamel.Map.atomize_keys(attrs)

        attrs
        |> Map.put(:data, Flamel.Map.stringify_keys(attrs[:data] || %{}))
        |> Map.put(:context, Flamel.Map.stringify_keys(attrs[:context] || %{}))
    end
  end
end
