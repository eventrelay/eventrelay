defmodule ER.Events do
  @moduledoc """
  The Events context.
  """
  require Logger
  import Ecto.Query, warn: false
  import ER
  alias ER.Repo
  alias Phoenix.PubSub

  alias ER.Events.Event
  alias ER.Events.Topic

  def from_events() do
    from(e in Event, as: :events)
  end

  def from_events_for_topic(topic_name: topic_name) do
    table_name = ER.Events.Event.table_name(topic_name)
    from(e in {table_name, Event}, as: :events)
  end

  def prepare_calcuate_query(
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        field_path: field_path,
        filters: filters
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
      Enum.reduce(filters, query, fn filter, query ->
        append_filter(query, filter)
      end)

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
        filters: filters
      ) do
    prepare_calcuate_query(
      topic_name: topic_name,
      topic_identifier: topic_identifier,
      field_path: field_path,
      filters: filters
    )
    |> apply_calculation_to_query(type)
    |> Repo.one()
  end

  @doc """
  Returns the list of events for a topic
  """
  def list_events_for_topic(
        offset: offset,
        batch_size: batch_size,
        topic_name: topic_name,
        topic_identifier: topic_identifier
      ) do
    list_events_for_topic(
      offset: offset,
      batch_size: batch_size,
      topic_name: topic_name,
      topic_identifier: topic_identifier,
      filters: []
    )
  end

  def list_events_for_topic(
        offset: offset,
        batch_size: batch_size,
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        filters: filters
      ) do
    query =
      from_events_for_topic(topic_name: topic_name)
      |> where(as(:events).topic_name == ^topic_name)
      |> apply_ordering(filters)
      |> where(not is_nil(as(:events).occurred_at))

    query =
      unless ER.empty?(topic_identifier) do
        query |> where(as(:events).topic_identifier == ^topic_identifier)
      else
        query
      end

    filters = ER.Filter.translate(filters)

    query =
      Enum.reduce(filters, query, fn filter, query ->
        append_filter(query, filter)
      end)

    ER.BatchedResults.new(query, %{"offset" => offset, "batch_size" => batch_size})
  end

  def list_events_for_topic(
        topic_name: topic_name,
        topic_identifier: topic_identifier
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

    Repo.all(query)
  end

  def list_events_for_topic(topic_name: topic_name) do
    list_events_for_topic(topic_name: topic_name, topic_identifier: nil)
  end

  def list_queued_events_for_topic(
        batch_size: batch_size,
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        subscription_id: subscription_id
      ) do
    subscription_id = Ecto.UUID.dump!(subscription_id)

    query =
      from_events_for_topic(topic_name: topic_name)
      |> where(as(:events).topic_name == ^topic_name)
      |> where(not is_nil(as(:events).occurred_at))
      |> where(^subscription_id not in as(:events).subscription_locks)
      |> limit(^batch_size)
      |> order_by(as(:events).offset)

    query =
      unless ER.empty?(topic_identifier) do
        query |> where(as(:events).topic_identifier == ^topic_identifier)
      else
        query
      end

    # IO.inspect(sql: Repo.to_sql(:all, query))
    Repo.all(query)
  end

  def lock_subscription_events(_subscription_id, []) do
    nil
  end

  def lock_subscription_events(subscription_id, events) do
    event = List.first(events)
    event_ids = Enum.map(events, & &1.id)
    source = Ecto.get_meta(event, :source)

    from(e in {source, Event},
      where: e.id in ^event_ids,
      update: [push: [subscription_locks: ^subscription_id]]
    )
    |> Repo.update_all([])
  end

  def list_events do
    from_events() |> Repo.all()
  end

  def apply_ordering(query, filters) do
    if has_date_filtering?(filters) do
      query
      |> order_by(asc: as(:events).occurred_at)
    else
      query
      |> order_by(as(:events).offset)
    end
  end

  def has_date_filtering?(filters) do
    Enum.any?(
      filters,
      fn
        filter when filter.field in ["start_date", "end_date"] -> true
        _filter -> false
      end
    )
  end

  defp maybe_parse_and_apply_datetime(query, value, func) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _} ->
        func.(query, datetime)

      _ ->
        query
    end
  end

  def parse_path(path) do
    String.split(path, ".", trim: true)
    |> Enum.map(&String.trim/1)
  end

  def cast_as(%{cast_as: :integer, value: value}) do
    to_integer(value)
  end

  def cast_as(%{cast_as: :boolean, value: value}) do
    to_boolean(value)
  end

  def cast_as(%{cast_as: :datetime, value: value}) do
    to_datetime(value)
  end

  def cast_as(%{value: value}) do
    value
  end

  def append_filter(query, %{field_path: "data." <> path, comparison: "="} = filter) do
    path = parse_path(path)
    value = cast_as(filter)

    query
    |> where(
      [events: events],
      json_extract_path(events.data, ^path) == ^value
    )
  end

  def append_filter(query, %{field_path: "data." <> path, comparison: "<"} = filter) do
    path = parse_path(path)
    value = cast_as(filter)

    query
    |> where(
      [events: events],
      json_extract_path(events.data, ^path) < ^value
    )
  end

  def append_filter(query, %{field_path: "data." <> path, comparison: ">"} = filter) do
    path = parse_path(path)
    value = cast_as(filter)

    query
    |> where(
      [events: events],
      json_extract_path(events.data, ^path) > ^value
    )
  end

  def append_filter(
        query,
        %{field_path: "context." <> path, comparison: "="} = filter
      ) do
    query
    |> where(
      [events: events],
      json_extract_path(events.context, ^parse_path(path)) == ^cast_as(filter)
    )
  end

  def append_filter(
        query,
        %{field_path: "context." <> path, comparison: ">"} = filter
      ) do
    query
    |> where(
      [events: events],
      json_extract_path(events.context, ^parse_path(path)) > ^cast_as(filter)
    )
  end

  def append_filter(
        query,
        %{field_path: "context." <> path, comparison: "<"} = filter
      ) do
    query
    |> where(
      [events: events],
      json_extract_path(events.context, ^parse_path(path)) < ^cast_as(filter)
    )
  end

  def append_filter(query, %{field: "data", value: value, comparison: "like"}) do
    query
    |> where(
      [events: events],
      fragment("data::text LIKE ?", ^"%#{value}%")
    )
  end

  def append_filter(query, %{field: "data", value: value, comparison: "ilike"}) do
    query
    |> where(
      [events: events],
      fragment("data::text ILIKE ?", ^"%#{value}%")
    )
  end

  # def append_filter(query, %{field: "data." <> path, value: value, comparison: "="}) do
  #   path =
  #     String.split(path, ".", trim: true)
  #     |> Enum.map(&String.trim/1)
  #
  #   query
  #   |> where([events: events], json_extract_path(events.data, ^path) == ^value)
  # end

  def append_filter(query, %{field: "start_date", value: value, comparison: ">="}) do
    maybe_parse_and_apply_datetime(query, value, fn query, datetime ->
      query
      |> where(
        [events: events],
        events.occurred_at >= ^datetime
      )
    end)
  end

  def append_filter(query, %{field: "start_date", value: value, comparison: ">"}) do
    maybe_parse_and_apply_datetime(query, value, fn query, datetime ->
      query
      |> where(
        [events: events],
        events.occurred_at > ^datetime
      )
    end)
  end

  def append_filter(query, %{field: "end_date", value: value, comparison: "<="}) do
    maybe_parse_and_apply_datetime(query, value, fn query, datetime ->
      query
      |> where(
        [events: events],
        events.occurred_at <= ^datetime
      )
    end)
  end

  def append_filter(query, %{field: "end_date", value: value, comparison: "<"}) do
    maybe_parse_and_apply_datetime(query, value, fn query, datetime ->
      query
      |> where([events: events], events.occurred_at < ^datetime)
    end)
  end

  def append_filter(query, %{field: field, comparison: "="} = filter) do
    field = String.to_atom(field)

    query
    |> where([events: events], field(events, ^field) == ^cast_as(filter))
  end

  def append_filter(query, %{field: field, comparison: "!="} = filter) do
    field = String.to_atom(field)

    query
    |> where([events: events], field(events, ^field) != ^cast_as(filter))
  end

  def append_filter(query, %{field: field, value: value, comparison: "like"}) do
    field = String.to_atom(field)

    query
    |> where([events: events], like(field(events, ^field), ^value))
  end

  def append_filter(query, %{field: field, value: value, comparison: "ilike"}) do
    field = String.to_atom(field)

    query
    |> where([events: events], ilike(field(events, ^field), ^value))
  end

  # TODO: Write a test
  def append_filter(query, %{field: field, value: value, comparison: "in"}) do
    field = String.to_atom(field)

    query
    |> where([events: events], field(events, ^field) in ^value)
  end

  # TODO: Write a test
  def append_filter(query, %{field: field, comparison: ">"} = filter) do
    field = String.to_atom(field)
    value = cast_as(filter)

    query
    |> where([events: events], field(events, ^field) > ^value)
  end

  def append_filter(query, %{field: field, comparison: ">="} = filter) do
    field = String.to_atom(field)
    value = cast_as(filter)

    query
    |> where([events: events], field(events, ^field) >= ^value)
  end

  # TODO: Write a test
  def append_filter(query, %{field: field, comparison: "<"} = filter) do
    field = String.to_atom(field)

    query
    |> where([events: events], field(events, ^field) < ^cast_as(filter))
  end

  def append_filter(query, %{field: field, comparison: "<="} = filter) do
    field = String.to_atom(field)

    query
    |> where([events: events], field(events, ^field) <= ^cast_as(filter))
  end

  @doc """
  Fallback
  """
  def append_filter(query, _filter) do
    # TODO: Noop for now...
    query
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
    uuid = Ecto.UUID.dump!(id)

    from_events_for_topic(topic_name: topic_name)
    |> where(as(:events).id == ^uuid)
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

  @spec create_event_for_topic(map()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  def create_event_for_topic(attrs \\ %{}) do
    occurred_at = attrs[:occurred_at]

    attrs =
      if ER.empty?(occurred_at) do
        Map.put(attrs, :occurred_at, DateTime.truncate(DateTime.now!("Etc/UTC"), :second))
      else
        case DateTime.from_iso8601(occurred_at) do
          {:ok, datetime, _} ->
            Map.put(attrs, :occurred_at, DateTime.truncate(datetime, :second))

          _ ->
            Logger.error(
              "create_event_for_topic failed to parse occurred_at value=#{inspect(occurred_at)}"
            )

            Map.put(attrs, :occurred_at, nil)
        end
      end

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
    uuid = Ecto.UUID.dump!(event.id)

    case from_events_for_topic(topic_name: topic_name)
         |> where(as(:events).id == ^uuid)
         |> Repo.delete_all() do
      {1, _} ->
        {:ok, event}

      _ ->
        {:error}
    end
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
             ER.Subscriptions.Delivery.create_table!(topic)
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
             ER.Subscriptions.Delivery.drop_table!(topic)
             topic
           end) do
        {:ok, topic} ->
          {:ok, topic}

        {:error, error} ->
          {:error, error}
      end
    rescue
      e in Postgrex.Error ->
        {:error, e.postgres.message}

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
