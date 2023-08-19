defmodule ER.Metrics do
  alias ER.Repo
  alias ER.Metrics.Metric
  alias ER.Events

  def get_value_for_metric(%Metric{
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        type: type,
        filters: filters
      })
      when type == :count do
    translated_filters = Events.get_translated_filters(filters)

    result =
      ER.Events.list_events_for_topic(
        offset: 0,
        batch_size: 1,
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        filters: translated_filters
      )

    result.total_count
  end

  def get_value_for_metric(%Metric{
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        field_path: field_path,
        type: type,
        filters: filters
      })
      when type in [:max, :min, :sum, :avg] do
    translated_filters = Events.get_translated_filters(filters)

    ER.Events.calculate_metric(
      topic_name: topic_name,
      topic_identifier: topic_identifier,
      field_path: field_path,
      type: type,
      filters: translated_filters
    )
  end

  def get_value_for_metric(_metric) do
    nil
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
