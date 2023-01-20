defmodule ER.Events do
  @moduledoc """
  The Events context.
  """
  require Logger
  import Ecto.Query, warn: false
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

  @doc """
  Returns the list of events for a topic
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

        insert_dead_letter_event(
          struct!(Event, e.changeset.changes),
          ER.Ecto.changeset_errors_to_list(e.changeset)
        )

      e in Postgrex.Error ->
        Logger.error("Postgrex error for event: #{inspect(e)}")
        insert_dead_letter_event(struct!(Event, attrs), [e.postgres.message])

      e ->
        Logger.error("Unknown error for event: #{inspect(e)}")
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
    # TODO rewrite so that dead letter is taken into consideration and support for ephemeral
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
    from_topics() |> Repo.all()
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
