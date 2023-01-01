defmodule ER.PaginatedResults do
  defstruct [
    :results,
    :page,
    :page_size,
    :next_page,
    :previous_page,
    :total_count,
    :total_pages
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

  def new(query, %{"page" => page, "page_size" => page_size}) do
    page = ER.to_integer(page)
    page_size = ER.to_integer(page_size)
    total_count = total_count(query)
    total_pages = total_pages(total_count, page_size)

    %PaginatedResults{
      results: results(query, page, page_size),
      page: page,
      page_size: page_size,
      next_page: next_page(page, total_pages),
      previous_page: previous_page(page),
      total_count: total_count,
      total_pages: total_pages
    }
  end

  def pagination_params(args) do
    page = Map.get(args, :page, 1)
    page_size = Map.get(args, :page_size, 100)
    %{"page" => page, "page_size" => page_size}
  end

  defp next_page(page, total_pages) do
    next_page_number = page + 1

    cond do
      next_page_number > total_pages ->
        nil

      true ->
        next_page_number
    end
  end

  defp previous_page(page) do
    previous_page_number = page - 1

    cond do
      previous_page_number <= 0 ->
        nil

      true ->
        previous_page_number
    end
  end

  defp results(query, page, page_size) do
    offset = page_size * (page - 1)

    query
    |> limit(^page_size)
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

  defp total_pages(total_count, page_size) do
    raw_total = total_count / page_size
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
