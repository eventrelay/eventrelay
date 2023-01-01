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

  # For Absinthe
  # defmacro paginated_object(payload_name, result_object_name) do
  #   quote location: :keep do
  #     object unquote(payload_name) do
  #       field(:pagination, non_null(:pagination), description: "Pagination information")

  #       field(:results, list_of(unquote(result_object_name)),
  #         description: "Object being paginated"
  #       )
  #     end
  #   end
  # end

  def new(query, %{"offset" => offset, "batch_size" => batch_size}) do
    offset = ER.to_integer(offset)
    batch_size = ER.to_integer(batch_size)
    total_count = total_count(query)
    total_batches = total_batches(total_count, batch_size)

    %BatchedResults{
      results: results(query, offset, batch_size),
      offset: offset,
      batch_size: batch_size,
      next_offset: next_offset(offset, batch_size, total_batches),
      previous_offset: previous_offset(offset, batch_size),
      total_count: total_count,
      total_batches: total_batches
    }
  end

  def batched_params(args) do
    offset = Map.get(args, :offset, 0)
    batch_size = Map.get(args, :batch_size, 100)
    %{"offset" => offset, "batch_size" => batch_size}
  end

  defp next_offset(offset, batch_size, total_batches) do
    next_offset_number = offset + batch_size

    cond do
      next_offset_number > total_batches ->
        nil

      true ->
        next_offset_number
    end
  end

  defp previous_offset(offset, batch_size) do
    previous_offset_number = offset - batch_size

    cond do
      previous_offset_number <= 0 ->
        nil

      true ->
        previous_offset_number
    end
  end

  defp results(query, offset, batch_size) do
    query
    |> limit(^batch_size)
    |> offset(^offset)
    |> Repo.all()
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

    cond do
      diff > 0 ->
        total + 1

      true ->
        total
    end
  end
end
