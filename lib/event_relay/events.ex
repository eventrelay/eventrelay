defmodule ER.Events do
  @moduledoc """
  The Events context.
  """
  require Logger
  import Ecto.Query, warn: false
  import ER.Events.Predicates
  alias ER.Repo
  alias Phoenix.PubSub
  alias ER.Destinations
  alias ER.Events.Event
  alias ER.Events.Topic

  def from_events() do
    from(e in Event, as: :events)
  end

  def from_events_for_topic(topic_name: topic_name) do
    table_name = ER.Events.Event.table_name(topic_name)

    from(e in {table_name, Event}, as: :events)
  end

  def prepare_calculate_query(
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        field_path: field_path,
        predicates: predicates
      ) do
    query =
      from_events_for_topic(topic_name: topic_name)
      |> where(as(:events).topic_name == ^topic_name)

    query =
      unless ER.empty?(topic_identifier) do
        query |> where(as(:events).topic_identifier == ^topic_identifier)
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

    path = parse_path(field_path)

    {query, path}
  end

  def apply_calculation_to_query({query, path}, :sum) do
    case path do
      ["data" | path_tail] ->
        select(
          query,
          [events: events],
          sum(type(json_extract_path(events.data, ^path_tail), :float))
        )

      ["context" | path_tail] ->
        select(
          query,
          [events: events],
          sum(type(json_extract_path(events.data, ^path_tail), :float))
        )

      _ ->
        query
    end
  end

  def apply_calculation_to_query({query, path}, :max) do
    case path do
      ["data" | path_tail] ->
        select(
          query,
          [events: events],
          max(type(json_extract_path(events.data, ^path_tail), :float))
        )

      ["context" | path_tail] ->
        select(
          query,
          [events: events],
          max(type(json_extract_path(events.data, ^path_tail), :float))
        )

      _ ->
        query
    end
  end

  def apply_calculation_to_query({query, path}, :min) do
    case path do
      ["data" | path_tail] ->
        select(
          query,
          [events: events],
          min(type(json_extract_path(events.data, ^path_tail), :float))
        )

      ["context" | path_tail] ->
        select(
          query,
          [events: events],
          min(type(json_extract_path(events.data, ^path_tail), :float))
        )

      _ ->
        query
    end
  end

  def apply_calculation_to_query({query, path}, :avg) do
    case path do
      ["data" | path_tail] ->
        select(
          query,
          [events: events],
          avg(type(json_extract_path(events.data, ^path_tail), :float))
        )

      ["context" | path_tail] ->
        select(
          query,
          [events: events],
          avg(type(json_extract_path(events.data, ^path_tail), :float))
        )

      _ ->
        query
    end
  end

  def calculate_metric(
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        field_path: field_path,
        type: type,
        predicates: predicates
      ) do
    prepare_calculate_query(
      topic_name: topic_name,
      topic_identifier: topic_identifier,
      field_path: field_path,
      predicates: predicates
    )
    |> apply_calculation_to_query(type)
    |> Repo.one()
  end

  @doc """
  Returns the list of events for a topic
  """
  def list_events_for_topic(
        topic_name,
        opts
      ) do
    offset = Keyword.get(opts, :offset, 0)
    batch_size = Keyword.get(opts, :batch_size, 100)
    topic_identifier = Keyword.get(opts, :topic_identifier, nil)

    predicates =
      opts
      |> Keyword.get(:predicates, nil)
      |> ER.Predicates.to_predicates()

    include_all = Keyword.get(opts, :include_all, false)
    return_batch = Keyword.get(opts, :return_batch, true)

    query =
      from_events_for_topic(topic_name: topic_name)
      |> where(as(:events).topic_name == ^topic_name)
      |> apply_ordering(predicates)
      |> where(not is_nil(as(:events).occurred_at))

    query =
      if include_all do
        query
      else
        where_available(query)
      end

    query =
      unless ER.empty?(topic_identifier) do
        query |> where(as(:events).topic_identifier == ^topic_identifier)
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

    # IO.inspect(sql: Repo.to_sql(:all, query))
    if return_batch do
      ER.BatchedResults.new(query, %{"offset" => offset, "batch_size" => batch_size})
    else
      Repo.all(query)
    end
  end

  defp where_available(query, now \\ DateTime.utc_now()) do
    where(query, [events: events], events.available_at <= ^now)
  end

  def list_queued_events_for_topic(
        batch_size: batch_size,
        destination_id: destination_id
      ) do
    destination = ER.Destinations.get_destination!(destination_id)

    list_queued_events_for_topic(
      batch_size: batch_size,
      destination: destination
    )
  end

  def list_queued_events_for_topic(
        batch_size: batch_size,
        destination: destination
      ) do
    destination_id = destination.id
    topic_name = destination.topic_name
    topic_identifier = destination.topic_identifier

    query =
      from_events_for_topic(topic_name: topic_name)
      |> where(as(:events).topic_name == ^topic_name)
      |> where(not is_nil(as(:events).occurred_at))
      |> where(^destination_id not in as(:events).destination_locks)
      |> limit(^batch_size)
      |> order_by(as(:events).offset)
      |> where_available()

    query =
      if Flamel.present?(destination.query) do
        case Predicated.Query.new(destination.query) do
          {:ok, predicates} ->
            conditions = apply_predicates(predicates, nil, nil)
            from query, where: ^conditions

          _ ->
            query
        end
      else
        query
      end

    query =
      unless ER.empty?(topic_identifier) do
        where(query, as(:events).topic_identifier == ^topic_identifier)
      else
        query
      end

    # IO.inspect(sql: Repo.to_sql(:all, query))
    Repo.all(query)
  end

  def lock_destination_events(_destination_id, []) do
    nil
  end

  def lock_destination_events(destination_id, events) do
    event = List.first(events)
    event_ids = Enum.map(events, & &1.id)
    source = Ecto.get_meta(event, :source)

    from(e in {source, Event},
      where: e.id in ^event_ids,
      update: [push: [destination_locks: ^destination_id]]
    )
    |> Repo.update_all([])
  end

  def unlock_destination_events(_destination_id, []) do
    nil
  end

  def unlock_destination_events(destination_id, events) do
    event = List.first(events)
    event_ids = Enum.map(events, & &1.id)
    source = Ecto.get_meta(event, :source)

    from(e in {source, Event},
      where: e.id in ^event_ids,
      update: [pull: [destination_locks: ^destination_id]]
    )
    |> Repo.update_all([])
  end

  def list_events do
    from_events() |> Repo.all()
  end

  def apply_ordering(query, _predicates) do
    order_by(query, as(:events).offset)
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResltsError` if the Event does not exist.

  ## Examples

      iex> get_event!(123)
      %Event{}

      iex> get_event!(456)
      ** (Ecto.NoResltsError)

  """
  def get_event!(id), do: Repo.get!(Event, id)

  def get_event_for_topic!(id, topic_name: topic_name) do
    from_events_for_topic(topic_name: topic_name)
    |> where(as(:events).id == ^id)
    |> Repo.one!()
  end

  @doc """
  Creates a event.

  ## Examples

      iex> create_event(%{field: value})
      {:ok, %Event{}}

      iex> create_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  def produce_event_for_topic(%{durable: true} = attrs) do
    create_event_for_topic(attrs)
    |> publish_event()
  end

  def produce_event_for_topic(attrs) do
    event = struct!(Event, attrs)
    publish_event({:ok, event})
  end

  defp put_datetime_if_empty(attrs, field) do
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

  @spec create_event_for_topic(map()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  def create_event_for_topic(attrs \\ %{}) do
    attrs =
      attrs
      |> put_datetime_if_empty(:occurred_at)
      |> put_datetime_if_empty(:available_at)

    try do
      # First attempt to insert it in the proper topic events table

      event =
        %Event{}
        |> ER.Events.Event.put_ecto_source(attrs[:topic_name])
        |> Event.changeset(attrs)
        |> Repo.insert!()

      {:ok, event}
    rescue
      e in Ecto.InvalidChangesetError ->
        Logger.error("Invalid changeset for event: #{inspect(e)}")
        Logger.error(Exception.format(:error, e, __STACKTRACE__))

        insert_dead_letter_event(
          struct!(Event, e.changeset.changes),
          ER.Ecto.changeset_errors_to_list(e.changeset)
        )

      e in Postgrex.Error ->
        Logger.error("Postgrex error for event: #{inspect(e)}")
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        insert_dead_letter_event(struct!(Event, attrs), [e.postgres.message])

      e ->
        Logger.error("Unknown error for event: #{inspect(e)}")
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        insert_dead_letter_event(struct!(Event, attrs), [e.message])
    end
  end

  defp insert_dead_letter_event(event, errors) do
    event =
      %{event | errors: errors}
      |> Ecto.put_meta(source: "dead_letter_events", state: :built)

    case Repo.insert(event) do
      {:ok, event} -> {:error, event}
      {:error, _changeset} -> {:error, event}
    end
  end

  def publish_event(
        {:ok, %Event{topic_name: topic_name, topic_identifier: topic_identifier} = event}
      ) do
    PubSub.broadcast(ER.PubSub, topic_name, {:event_created, event})
    full_topic = ER.Events.Topic.build_topic(topic_name, topic_identifier)

    if full_topic != topic_name do
      PubSub.broadcast(ER.PubSub, full_topic, {:event_created, event})
    end

    Flamel.Task.background(
      fn ->
        Destinations.list_destinations(types: [:websocket])
        |> Enum.map(fn destination ->
          if ER.Events.ChannelCache.any_sockets?(destination.id) do
            ERWeb.Endpoint.broadcast("events:#{destination.id}", "event:published", event)
          else
            Logger.debug(
              "#{__MODULE__}.publish_event(#{inspect(event)}) for destination=#{inspect(destination)} do not push to websocket because there are no sockets connected on node=#{inspect(Node.self())}"
            )
          end
        end)
      end,
      env: ER.env()
    )

    {:ok, event}
  end

  def publish_event({:error, event}) do
    {:error, event}
  end

  @doc """
  Updates a event.

  ## Examples

      iex> update_event(event, %{field: new_value})
      {:ok, %Event{}}

      iex> update_event(event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a event.

  ## Examples

      iex> delete_event(event)
      {:ok, %Event{}}

      iex> delete_event(event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Deletes a event in a topic table

  ## Examples

      iex> delete_event(event, topic_name: topic_name)
      {:ok, %Event{}}

      iex> delete_event(event, topic_name: topic_name)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event(%Event{} = event, topic_name: topic_name) do
    id = event.id

    case from_events_for_topic(topic_name: topic_name)
         |> where(as(:events).id == ^id)
         |> Repo.delete_all() do
      {1, _} ->
        {:ok, event}

      _ ->
        {:error}
    end
  end

  def delete_events_for_topic_before(topic_name, datetime, query_filter) do
    predicates = ER.Predicates.to_predicates(query_filter)

    query =
      from_events_for_topic(topic_name: topic_name)
      |> where(as(:events).occurred_at < ^datetime)

    query =
      if Flamel.present?(predicates) do
        conditions = apply_predicates(predicates, nil, nil)
        from query, where: ^conditions
      else
        query
      end

    Repo.delete_all(query)
  end

  def delete_events_for_topic_over(topic_name, max_count, query_filter) do
    predicates = ER.Predicates.to_predicates(query_filter)

    subquery =
      from(e in from_events_for_topic(topic_name: topic_name),
        order_by: [desc: e.occurred_at],
        limit: ^max_count,
        select: e.id
      )

    query =
      from_events_for_topic(topic_name: topic_name)
      |> where([events: events], events.id not in subquery(subquery))

    query =
      if Flamel.present?(predicates) do
        conditions = apply_predicates(predicates, nil, nil)
        from query, where: ^conditions
      else
        query
      end

    Repo.delete_all(query)
  end

  def delete_events_for_topic!(%Topic{} = topic) do
    from_events_for_topic(topic_name: topic.name)
    |> Repo.delete_all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.

  ## Examples

      iex> change_event(event)
      %Ecto.Changeset{data: %Event{}}

  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  alias ER.Events.Topic

  def from_topics() do
    from(t in Topic, as: :topics)
  end

  @doc """
  Returns the list of topics.
  """

  def list_topics(names: names) do
    from_topics() |> where(as(:topics).name in ^names) |> Repo.all()
  end

  def list_topics do
    from_topics() |> where(as(:topics).name != ^"default") |> Repo.all()
  end

  @doc """
  Gets a single topic.

  Raises `Ecto.NoResultsError` if the Topic does not exist.

  ## Examples

      iex> get_topic!(123)
      %Topic{}

      iex> get_topic!(456)
      ** (Ecto.NoResultsError)

  """
  def get_topic!(id), do: Repo.get!(Topic, id)

  def get_topic(id), do: Repo.get(Topic, id)

  @doc """
  Creates a topic.
  """
  def create_topic(attrs) do
    try do
      case Repo.transaction(fn ->
             topic =
               %Topic{}
               |> Topic.changeset(attrs)
               |> Repo.insert!()

             ER.Events.Event.create_table!(topic)
             ER.Destinations.Delivery.create_table!(topic)
             topic
           end) do
        {:ok, topic} ->
          {:ok, topic}

        {:error, error} ->
          {:error, error}
      end
    rescue
      e in Ecto.InvalidChangesetError ->
        {:error, e.changeset}

      e in Postgrex.Error ->
        {:error, e.postgres.message}

      e ->
        Logger.error("Error creating topic: #{inspect(e)}")
        {:error, e.message}
    end
  end

  @doc """
  Updates a topic.

  ## Examples

      iex> update_topic(topic, %{field: new_value})
      {:ok, %Topic{}}

      iex> update_topic(topic, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_topic(%Topic{} = topic, attrs) do
    topic
    |> Topic.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a topic.
  """
  def delete_topic(%Topic{} = topic) do
    try do
      case Repo.transaction(fn ->
             delete_events_for_topic!(topic)
             {:ok, topic} = Repo.delete(topic)

             ER.Events.Event.drop_table!(topic)
             ER.Destinations.Delivery.drop_table!(topic)
             topic
           end) do
        {:ok, topic} ->
          {:ok, topic}

        {:error, error} ->
          {:error, error}
      end
    rescue
      e in Postgrex.Error ->
        msg = e.postgres.message

        if String.contains?(msg, "does not exist") do
          {:ok, topic}
        else
          {:error, msg}
        end

      e ->
        Logger.error("Error creating topic: #{inspect(e)}")
        {:error, e.message}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking topic changes.

  ## Examples

      iex> change_topic(topic)
      %Ecto.Changeset{data: %Topic{}}

  """

  def change_topic(%Topic{} = topic, attrs \\ %{}) do
    Topic.changeset(topic, attrs)
  end
end
