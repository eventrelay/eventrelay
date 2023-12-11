defmodule ER.Metrics do
  alias ER.Repo
  alias ER.Metrics.Metric
  import Ecto.Query
  alias Phoenix.PubSub
  import ER.Metrics.Predicates

  def publish_metric_updates(updates) do
    Enum.map(updates, fn {value, _event, metric} ->
      PubSub.broadcast(ER.PubSub, "metric:updated", {:metric_updated, metric, value})
    end)

    updates
  end

  def build_metric_updates(
        topic_name: topic_name,
        topic_identifier: topic_identifier
      ) do
    ER.Metrics.list_metrics_for_topic(
      topic_name,
      topic_identifier,
      where: [produce_update_event: true]
    )
    |> Enum.map(fn metric ->
      value = ER.Metrics.get_value_for_metric(metric)

      {value,
       %ER.Events.Event{
         name: "metric.updated",
         topic_name: topic_name,
         topic_identifier: topic_identifier,
         durable: false,
         data: %{
           "value" => value,
           "metric" => %{
             "type" => to_string(metric.type),
             "name" => metric.name,
             "field_path" => metric.field_path,
             "id" => metric.id
           }
         },
         source: "event_relay"
       }, metric}
    end)
  end

  def get_value_for_metric(%Metric{
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        type: type,
        query: query
      })
      when type == :count do
    predicates = ER.Predicates.to_predicates(query)

    result =
      ER.Events.list_events_for_topic(
        offset: 0,
        batch_size: 1,
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        predicates: predicates
      )

    result.total_count
  end

  def get_value_for_metric(%Metric{
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        field_path: field_path,
        type: type,
        query: query
      })
      when type in [:max, :min, :sum, :avg] do
    predicates = ER.Predicates.to_predicates(query)

    ER.Events.calculate_metric(
      topic_name: topic_name,
      topic_identifier: topic_identifier,
      field_path: field_path,
      type: type,
      predicates: predicates
    )
  end

  def get_value_for_metric(_metric) do
    nil
  end

  def from_metrics() do
    from(m in Metric, as: :metrics)
  end

  @doc """
  Returns the list of metrics.

  ## Examples

      iex> list_metrics()
      [%Metric{}, ...]

  """
  def list_metrics do
    Repo.all(Metric)
  end

  def list_metrics(
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        query: query,
        page: page,
        page_size: page_size
      ) do
    predicates = ER.Predicates.to_predicates(query)

    list_metrics(
      topic_name: topic_name,
      topic_identifier: topic_identifier,
      predicates: predicates,
      page: page,
      page_size: page_size
    )
  end

  def list_metrics(
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        predicates: predicates,
        page: page,
        page_size: page_size
      ) do
    query =
      from_metrics()
      |> where(as(:metrics).topic_name == ^topic_name)

    query =
      unless ER.empty?(topic_identifier) do
        query |> where(as(:metrics).topic_identifier == ^topic_identifier)
      else
        query
      end

    query =
      if Flamel.present?(predicates) do
        conditions = apply_predicates(predicates, nil, nil)
        from query, where: ^conditions
      else
        query
      end

    ER.PaginatedResults.new(query, %{"page" => page, "page_size" => page_size})
  end

  def list_metrics_for_topic(topic_name, topic_identifier, where: where) do
    query =
      from_metrics()
      |> where(as(:metrics).topic_name == ^topic_name)

    query =
      if topic_identifier do
        where(query, as(:metrics).topic_identifier == ^topic_identifier)
      else
        query
      end

    query =
      Enum.reduce(where, query, fn {k, v}, query ->
        where(query, field(as(:metrics), ^k) == ^v)
      end)

    Repo.all(query)
  end

  @doc """
  Gets a single metric.

  Raises `Ecto.NoResultsError` if the Metric does not exist.

  ## Examples

      iex> get_metric!(123)
      %Metric{}

      iex> get_metric!(456)
      ** (Ecto.NoResultsError)

  """
  def get_metric!(id), do: Repo.get!(Metric, id)

  def get_metric(id), do: Repo.get(Metric, id)

  @doc """
  Creates a metric.

  ## Examples

      iex> create_metric(%{field: value})
      {:ok, %Metric{}}

      iex> create_metric(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_metric(attrs \\ %{}) do
    %Metric{}
    |> Metric.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a metric.

  ## Examples

      iex> update_metric(metric, %{field: new_value})
      {:ok, %Metric{}}

      iex> update_metric(metric, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_metric(%Metric{} = metric, attrs) do
    metric
    |> Metric.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a metric.

  ## Examples

      iex> delete_metric(metric)
      {:ok, %Metric{}}

      iex> delete_metric(metric)
      {:error, %Ecto.Changeset{}}

  """
  def delete_metric(%Metric{} = metric) do
    Repo.delete(metric)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking metric changes.

  ## Examples

      iex> change_metric(metric)
      %Ecto.Changeset{data: %Metric{}}

  """
  def change_metric(%Metric{} = metric, attrs \\ %{}) do
    Metric.changeset(metric, attrs)
  end
end
