defmodule ER.Events do
  @moduledoc """
  The Events context.
  """
  require Logger
  import Ecto.Query, warn: false
  alias ER.Repo
  alias Phoenix.PubSub

  alias ER.Events.Event

  def from_events() do
    from(e in Event, as: :events)
  end

  def from_events_for_topic(topic_name: topic_name) do
    table_name = ER.Events.Schema.build_topic_event_table_name(topic_name)
    from(e in {table_name, Event}, as: :events)
  end

  @doc """
  Returns the list of events for a topic

  ## Examples

      iex> list_events_for_topic()
      [%Event{}, ...]

  """
  def list_events_for_topic(
        offset: offset,
        batch_size: batch_size,
        topic_name: topic_name,
        topic_identifier: topic_identifier
      ) do
    query =
      from_events_for_topic(topic_name: topic_name)
      |> where(as(:events).topic_name == ^topic_name)
      |> order_by(as(:events).offset)

    query =
      unless ER.empty?(topic_identifier) do
        query |> where(as(:events).topic_identifier == ^topic_identifier)
      else
        query
      end

    ER.BatchedResults.new(query, %{"offset" => offset, "batch_size" => batch_size})
  end

  def list_events do
    from_events() |> Repo.all()
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

  @spec create_event_for_topic(map()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  def create_event_for_topic(attrs \\ %{}) do
    changeset = %Event{} |> Event.changeset(attrs)

    try do
      # First attempt to insert it in the proper topic events table
      event =
        changeset
        |> put_ecto_source_for_topic()
        |> Repo.insert!()
        |> publish_event()

      {:ok, event}
    rescue
      e in Ecto.InvalidChangesetError ->
        Logger.error("Invalid changeset for event: #{inspect(e)}")

        event =
          struct!(Event, e.changeset.changes)
          |> Ecto.put_meta(source: "dead_letter_events", state: :built)

        errors = ER.Ecto.changeset_errors_to_list(e.changeset)
        event = %{event | errors: errors}
        Repo.insert(event)

      e in Postgrex.Error ->
        Logger.error("Postgrex error for event: #{inspect(e)}")

        event =
          struct!(Event, attrs)
          |> Ecto.put_meta(source: "dead_letter_events", state: :built)

        event = %{event | errors: [e.postgres.message]}
        Repo.insert(event)

      e ->
        Logger.error("Unknown error for event: #{inspect(e)}")

        event =
          struct!(Event, attrs)
          |> Ecto.put_meta(source: "dead_letter_events", state: :built)

        event = %{event | errors: [e.message]}
        Repo.insert(event)
    end
  end

  def publish_event(%Event{topic_name: topic_name, topic_identifier: topic_identifier} = event) do
    PubSub.broadcast(ER.PubSub, topic_name, {:event_created, event})
    full_topic = ER.Events.Topic.build_topic(topic_name, topic_identifier)

    if full_topic != topic_name do
      PubSub.broadcast(ER.PubSub, full_topic, {:event_created, event})
    end

    event
  end

  def put_ecto_source_for_topic(%Event{} = event, attrs) do
    source = ER.Events.Schema.build_topic_event_table_name(attrs[:topic_name])

    Ecto.put_meta(event,
      source: source,
      state: :built
    )
  end

  def put_ecto_source_for_topic(%Ecto.Changeset{} = changeset) do
    %{changeset | data: put_ecto_source_for_topic(changeset.data, changeset.changes)}
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
  Returns an `%Ecto.Changeset{}` for tracking event changes.

  ## Examples

      iex> change_event(event)
      %Ecto.Changeset{data: %Event{}}

  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  alias ER.Events.Topic

  @doc """
  Returns the list of topics.

  ## Examples

      iex> list_topics()
      [%Topic{}, ...]

  """
  def list_topics do
    Repo.all(Topic)
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

  @doc """
  Creates a topic.

  ## Examples

      iex> create_topic(%{field: value})
      {:ok, %Topic{}}

      iex> create_topic(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_topic(attrs \\ %{}) do
    %Topic{}
    |> Topic.changeset(attrs)
    |> Repo.insert()
  end

  def create_topic_and_table(attrs \\ %{}) do
    try do
      case Repo.transaction(fn ->
             topic =
               %Topic{}
               |> Topic.changeset(attrs)
               |> Repo.insert!()

             ER.Events.Schema.create_topic_event_table!(topic)
             ER.Events.Schema.create_topic_delivery_table!(topic)
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

  ## Examples

      iex> delete_topic(topic)
      {:ok, %Topic{}}

      iex> delete_topic(topic)
      {:error, %Ecto.Changeset{}}

  """
  def delete_topic(%Topic{} = topic) do
    try do
      case Repo.transaction(fn ->
             {:ok, topic} = Repo.delete(topic)

             ER.Events.Schema.drop_topic_event_table!(topic)
             ER.Events.Schema.drop_topic_delivery_table!(topic)
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
