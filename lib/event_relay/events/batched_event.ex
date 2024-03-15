defmodule ER.Events.BatchedEvent do
  def new_with_defaults(attrs) do
    attrs
    |> ensure_id()
    |> ensure_prev_id()
    |> ensure_datetime(:occurred_at)
    |> ensure_datetime(:available_at)
    |> decode_data()
    |> decode_data_schema()
    |> drop_fields()
  end

  defp drop_fields(attrs) do
    Map.drop(attrs, [:data_json, :data_schema_json, :durable])
  end

  defp ensure_prev_id(%{prev_id: prev_id} = attrs) do
    if Flamel.blank?(prev_id), do: Map.put(attrs, :prev_id, nil), else: attrs
  end

  defp decode_data(%{data_json: data_json} = attrs) when is_binary(data_json) do
    case Jason.decode(data_json) do
      {:ok, data} -> Map.put(attrs, :data, data)
      _ -> attrs
    end
  end

  defp decode_data(attrs) do
    attrs
  end

  defp decode_data_schema(%{data_schema_json: data_schema_json} = attrs)
       when is_binary(data_schema_json) do
    case Jason.decode(data_schema_json) do
      {:ok, data_schema} -> Map.put(attrs, :data_schema, data_schema)
      _ -> attrs
    end
  end

  defp decode_data_schema(attrs) do
    attrs
  end

  defp ensure_id(attrs) do
    value = attrs[:id]

    value =
      if ER.empty?(value) do
        Uniq.UUID.uuid7()
      else
        value
      end

    Map.put(attrs, :id, value)
  end

  defp ensure_datetime(attrs, field) do
    field = Flamel.to_atom(field)
    value = attrs[field]

    value =
      if ER.empty?(value) do
        DateTime.truncate(DateTime.now!("Etc/UTC"), :second)
      else
        Flamel.Moment.to_datetime(value)
      end

    Map.put(attrs, field, value)
  end
end
