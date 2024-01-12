defmodule ER.Destinations do
  @moduledoc """
  The Destinations context.
  """
  require Logger
  alias Phoenix.PubSub, as: PubSub
  import Ecto.Query, warn: false
  import Flamel.Wrap
  alias ER.Repo
  alias ER.Destinations.Destination

  def from_destinations() do
    from(s in Destination, as: :destinations)
  end

  @doc """
  Returns the list of destinations.
  """
  def list_destinations() do
    from_destinations() |> Repo.all()
  end

  def list_destinations(ids: ids) when is_list(ids) do
    from_destinations() |> where(as(:destinations).id in ^ids) |> Repo.all()
  end

  def list_destinations(page: page, page_size: page_size) do
    from_destinations()
    |> ER.PaginatedResults.new(%{"page" => page, "page_size" => page_size})
  end

  @doc """
  Gets a single destination.
  """
  def get_destination!(id), do: Repo.get!(Destination, id)

  def get_destination(id), do: Repo.get(Destination, id)

  @doc """
  Creates a destination.
  """
  def create_destination(attrs \\ %{}) do
    %Destination{}
    |> Destination.changeset(attrs)
    |> Repo.insert()
    |> publish_destination_created()
  end

  def publish_destination_created({:ok, destination}) do
    PubSub.broadcast(ER.PubSub, "destination:created", {:destination_created, destination})
    {:ok, destination}
  end

  def publish_destination_created(result) do
    result
  end

  def publish_destination_updated({:ok, destination}) do
    PubSub.broadcast(ER.PubSub, "destination:updated", {:destination_updated, destination})
    {:ok, destination}
  end

  def publish_destination_updated(result) do
    result
  end

  def publish_destination_deleted({:ok, destination}) do
    PubSub.broadcast(ER.PubSub, "destination:deleted", {:destination_deleted, destination})
    {:ok, destination}
  end

  def publish_destination_deleted(result) do
    result
  end

  @doc """
  Updates a destination.

  ## Examples

      iex> update_destination(destination, %{field: new_value})
      {:ok, %Destination{}}

      iex> update_destination(destination, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_destination(%Destination{} = destination, attrs) do
    destination
    |> Destination.changeset(attrs)
    |> Repo.update()
    |> publish_destination_updated()
  end

  @doc """
  Deletes a destination.

  ## Examples

      iex> delete_destination(destination)
      {:ok, %Destination{}}

      iex> delete_destination(destination)
      {:error, %Ecto.Changeset{}}

  """
  def delete_destination(%Destination{} = destination) do
    Repo.delete(destination)
    |> publish_destination_deleted()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking destination changes.

  ## Examples

      iex> change_destination(destination)
      %Ecto.Changeset{data: %Destination{}}

  """
  def change_destination(%Destination{} = destination, attrs \\ %{}) do
    Destination.changeset(destination, attrs)
  end

  alias ER.Destinations.Delivery

  def from_deliveries_for_topic(topic_name: topic_name) do
    table_name = ER.Destinations.Delivery.table_name(topic_name)
    from(e in {table_name, Delivery}, as: :deliveries)
  end

  def list_deliveries_for_destination(topic_name, destination_id, opts \\ []) do
    query =
      from_deliveries_for_topic(topic_name: topic_name)
      |> where(as(:deliveries).destination_id == ^destination_id)

    query =
      if status = Keyword.get(opts, :status, nil) do
        where(query, as(:deliveries).status == ^to_string(status))
      else
        query
      end

    Repo.all(query)
  end

  def list_events_for_deliveries(topic_name, deliveries) do
    event_ids = Enum.map(deliveries, fn d -> "'#{d.event_id}'" end) |> Enum.join(", ")

    predicates =
      case Predicated.Query.new("id in [#{event_ids}]") do
        {:ok, predicates} -> predicates
        _ -> []
      end

    batched_results =
      ER.Events.list_events_for_topic(
        topic_name,
        offset: 0,
        batch_size: 100_000,
        topic_identifier: nil,
        predicates: predicates
      )

    batched_results.results
  end

  @doc """
  Returns the list of deliveries.

  ## Examples

      iex> list_deliveries()
      [%Delivery{}, ...]

  """
  def list_deliveries do
    Repo.all(Delivery)
  end

  def list_deliveries_for_topic(topic_name: topic_name) do
    from_deliveries_for_topic(topic_name: topic_name)
    |> Repo.all()
  end

  @doc """
  Gets a single delivery.
  """
  def get_delivery!(id),
    do: Repo.get!(Delivery, id) |> Repo.preload(destination: [:topic])

  def get_delivery_for_topic!(id, topic_name: topic_name) do
    from_deliveries_for_topic(topic_name: topic_name)
    |> where(as(:deliveries).id == ^id)
    |> preload([:destination])
    |> Repo.one!()
  end

  @doc """
  Returns a deliver for a topic by the event id
  """
  @spec get_delivery_for_topic_by_event_id(binary(), keyword()) :: Delivery.t() | nil
  def get_delivery_for_topic_by_event_id(event_id, topic_name: topic_name) do
    from_deliveries_for_topic(topic_name: topic_name)
    |> where(as(:deliveries).event_id == ^event_id)
    |> preload([:destination])
    |> Repo.one()
  end

  @doc """
  Returns a delivery is finds based on Event ID or creates a new delivery
  """
  @spec get_or_create_delivery_for_topic_by_event_id(binary(), map()) :: Deliver.t()
  def get_or_create_delivery_for_topic_by_event_id(topic_name, attrs) do
    event_id = attrs[:event_id]

    if delivery = get_delivery_for_topic_by_event_id(event_id, topic_name: topic_name) do
      ok(delivery)
    else
      create_delivery_for_topic(topic_name, attrs)
    end
  end

  @doc """
  Creates a delivery.
  """
  def create_delivery(attrs \\ %{}) do
    %Delivery{}
    |> Delivery.changeset(attrs)
    |> Repo.insert()
  end

  def build_delivery_for_topic(topic_name) do
    struct!(
      Delivery,
      %{id: Ecto.UUID.generate()}
    )
    |> ER.Destinations.Delivery.put_ecto_source(topic_name)
  end

  @spec create_delivery_for_topic(binary(), map(), Delivery.t()) ::
          {:ok, Delivery.t()} | {:error, Ecto.Changeset.t()}
  def create_delivery_for_topic(topic_name, attrs \\ %{}, delivery \\ %Delivery{}) do
    changeset =
      delivery
      |> ER.Destinations.Delivery.put_ecto_source(topic_name)
      |> Delivery.changeset(attrs)

    try do
      # First attempt to insert it in the proper topic deliveries table
      delivery =
        changeset
        |> Repo.insert!()

      {:ok, delivery}
    rescue
      e in Ecto.InvalidChangesetError ->
        {:error, e.changeset}

      e in Postgrex.Error ->
        Logger.debug("Postgrex error for delivery=#{inspect(attrs)} exception=#{inspect(e)}")
        {:error, e.postgres.message}

      e ->
        Logger.error("Unknown error for event: #{inspect(e)}")
        {:error, e.message}
    end
  end

  def put_ecto_source_for_topic(%Delivery{} = delivery, topic_name) do
    # TODO: refactor this to use protocols along with the event source switching
    source = ER.Destinations.Delivery.table_name(topic_name)

    Ecto.put_meta(delivery,
      source: source,
      state: :built
    )
  end

  def put_ecto_source_for_topic(%Ecto.Changeset{} = changeset, topic_name) do
    %{changeset | data: put_ecto_source_for_topic(changeset.data, topic_name)}
  end

  @doc """
  Updates a delivery.

  ## Examples

      iex> update_delivery(delivery, %{field: new_value})
      {:ok, %Delivery{}}

      iex> update_delivery(delivery, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_delivery(%Delivery{} = delivery, attrs) do
    delivery
    |> Delivery.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Will update all deliveries with the given updates. It assumes that all deliveries have the same Ecto source.
  """
  def update_all_deliveries(topic_name, deliveries, updates) do
    delivery_ids = Enum.map(deliveries, fn d -> d.id end)

    from_deliveries_for_topic(topic_name: topic_name)
    |> where(as(:deliveries).id in ^delivery_ids)
    |> Repo.update_all(updates)
  end

  @doc """
  Deletes a delivery.

  ## Examples

      iex> delete_delivery(delivery)
      {:ok, %Delivery{}}

      iex> delete_delivery(delivery)
      {:error, %Ecto.Changeset{}}

  """
  def delete_delivery(%Delivery{} = delivery) do
    Repo.delete(delivery)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking delivery changes.

  ## Examples

      iex> change_delivery(delivery)
      %Ecto.Changeset{data: %Delivery{}}

  """
  def change_delivery(%Delivery{} = delivery, attrs \\ %{}) do
    Delivery.changeset(delivery, attrs)
  end
end
