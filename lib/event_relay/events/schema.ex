defmodule ER.Events.Schema do
  alias ER.Repo
  alias ER.Events.Topic

  def create_topic_event_table(topic_name) do
    Ecto.Adapters.SQL.query!(Repo, build_topic_event_table_name(topic_name), [])
  end

  def drop_topic_event_table(topic_name) do
    Ecto.Adapters.SQL.query!(Repo, build_drop_topic_event_table_query(topic_name), [])
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
    "#{topic.name}_events"
  end

  def build_topic_event_table_name(topic_name) do
    "#{topic_name}_events"
  end

  @doc """
  Builds a query to create a table for the given topic name.
  """
  def build_create_topic_event_table_query(topic_name) do
    """
    CREATE TABLE `#{build_topic_event_table_name(topic_name)}` AS SELECT * FROM `events`;
    """
  end

  @doc """
  Builds a query to drop a table for the given topic name.
  """
  def build_drop_topic_event_table_query(topic_name) do
    """
    DROP TABLE `#{build_topic_event_table_name(topic_name)}`;
    """
  end
end
