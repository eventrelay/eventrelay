defmodule ER.BatchedResults do
  defstruct [
    :results,
    :offset,
    :batch_size,
    :next_offset,
    :previous_offset,
    :total_count,
    :total_batches
  ]

  import Ecto.Query
  alias __MODULE__
  alias ER.Repo

  def new(query, %{"offset" => offset, "batch_size" => batch_size}, result_transformer \\ nil) do
    offset = ER.to_integer(offset)
    batch_size = ER.to_integer(batch_size)
    total_count = total_count(query)
    total_batches = total_batches(total_count, batch_size)
    next_offset = next_offset(offset, batch_size, total_count)
    previous_offset = previous_offset(offset, batch_size)
    results = results(query, offset, batch_size, result_transformer)

    %BatchedResults{
      results: results,
      offset: offset,
      batch_size: batch_size,
      next_offset: next_offset,
      previous_offset: previous_offset,
      total_count: total_count,
      total_batches: total_batches
    }
  end

  def batched_params(args) do
    offset = Map.get(args, :offset, 0)
    batch_size = Map.get(args, :batch_size, 100)
    %{"offset" => offset, "batch_size" => batch_size}
  end

  defp next_offset(offset, batch_size, total_count) do
    next_offset_number = offset + batch_size

    if next_offset_number > total_count do
      nil
    else
      next_offset_number
    end
  end

  defp previous_offset(offset, batch_size) do
    previous_offset_number = offset - batch_size

    if previous_offset_number < 0 do
      nil
    else
      previous_offset_number
    end
  end

  defp results(query, offset, batch_size, result_transformer) do
    results =
      query
      |> limit(^batch_size)
      |> offset(^offset)
      |> Repo.all()

    if result_transformer do
      Enum.map(results, fn result -> result_transformer.(result) end)
    else
      results
    end
  end

  defp total_count(query) do
    query
    |> exclude(:order_by)
    |> exclude(:preload)
    |> exclude(:select)
    |> select([t], count(t.id))
    |> Repo.one()
  end

  defp total_batches(total_count, batch_size) do
    raw_total = total_count / batch_size
    total = trunc(raw_total)
    diff = raw_total - total

    if diff > 0 do
      total + 1
    else
      total
    end
  end
end
