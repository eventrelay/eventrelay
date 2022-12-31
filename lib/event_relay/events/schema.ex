defmodule ER.Events.Schema do
  alias ER.Repo
  alias ER.Events.Topic

  def create_topic_event_table!(topic_or_name) do
    query = build_create_topic_event_table_query(topic_or_name)
    Ecto.Adapters.SQL.query!(Repo, query, [])
    query = build_fk_topic_event_table_query(topic_or_name)
    Ecto.Adapters.SQL.query!(Repo, query, [])
  end

  def drop_topic_event_table!(topic_or_name) do
    Ecto.Adapters.SQL.query!(Repo, build_drop_topic_event_table_query(topic_or_name), [])
  end

  @doc """
  Creates a table name for the given topic name.

  Examples:

    iex> ER.Events.Schema.build_topic_event_table_name("users")
    "users_events"

    iex> topic = %ER.Events.Topic{name: "test"}
    iex> ER.Events.Schema.build_topic_event_table_name(topic)
    "test_events"
  """

  def build_topic_event_table_name(%Topic{} = topic) do
    build_topic_event_table_name(topic.name)
  end

  def build_topic_event_table_name(topic_name) do
    topic_name <> "_events"
  end

  @doc """
  Checks that a topic event table exists and returns it's name.

  Examples:
    iex> import ER.Factory
    iex> insert(:topic, name: "users")
    iex> ER.Events.Schema.get_topic_event_table_name("users")
    "users_events"

    iex> import ER.Factory
    iex> insert(:topic, name: "test")
    iex> topic = %ER.Events.Topic{name: "test"}
    iex> ER.Events.Schema.get_topic_event_table_name(topic)
    "test_events"
  """
  def get_topic_event_table_name(%Topic{} = topic) do
    get_topic_event_table_name(topic.name)
  end

  def get_topic_event_table_name(topic_name) do
    # Optimize this
    topic_names = ER.Events.list_topics() |> Enum.map(& &1.name)

    if Enum.member?(topic_names, topic_name) do
      topic_name <> "_events"
    else
      # Send to dead letter table
      "events"
    end
  end

  @doc """
  Builds a query to create a table for the given topic name.
  """
  def build_create_topic_event_table_query(topic_or_name) do
    """
    CREATE TABLE #{build_topic_event_table_name(topic_or_name)} ( LIKE events INCLUDING ALL );
    """
  end

  @doc """
  Buils a query to create a foreign key constraint for the given topic name.
  """
  def build_fk_topic_event_table_query(topic_or_name) do
    """
    ALTER TABLE #{build_topic_event_table_name(topic_or_name)} ADD CONSTRAINT "#{build_topic_event_table_name(topic_or_name)}_topic_name_fkey" FOREIGN KEY (topic_name) REFERENCES topics(name);
    """
  end

  @doc """
  Builds a query to drop a table for the given topic name.
  """
  def build_drop_topic_event_table_query(topic_or_name) do
    """
    DROP TABLE #{build_topic_event_table_name(topic_or_name)};
    """
  end
end
