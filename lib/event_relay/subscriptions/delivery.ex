defmodule ER.Subscriptions.Delivery do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Events.Topic
  alias ER.Repo
  @behaviour ER.TopicTable

  @derive {Jason.Encoder,
           only: [
             :id,
             :attempts
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "deliveries" do
    field :attempts, {:array, :map}, default: []
    field :success, :boolean, default: false
    field :event_id, :binary_id

    belongs_to :subscription, ER.Subscriptions.Subscription,
      foreign_key: :subscription_id,
      references: :id,
      type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [:attempts, :event_id, :subscription_id])
    |> validate_required([:event_id, :subscription_id])
    |> unique_constraint([:event_id, :subscription_id])
  end

  @doc """
  Changes the source in the struct to the topic table name
  """
  @impl true
  def put_ecto_source(%__MODULE__{} = delivery, topic_name) do
    source = table_name(topic_name)

    Ecto.put_meta(delivery,
      source: source,
      state: :built
    )
  end

  @doc """
  Creates a table name for the given topic name.

  Examples:

    iex> ER.Subscriptions.Delivery.table_name("users")
    "users_events"

    iex> topic = %ER.Events.Topic{name: "test"}
    iex> ER.Subscriptions.Delivery.table_name(topic)
    "test_events"
  """
  @impl true
  def table_name(%Topic{} = topic) do
    table_name(topic.name)
  end

  def table_name(topic_name) do
    topic_name <> "_deliveries"
  end

  @doc """
  Builds a query to create a table for the given topic name.
  """
  @impl true
  def create_queries(topic_or_name) do
    table_name = table_name(topic_or_name)

    [
      """
      CREATE TABLE IF NOT EXISTS #{table_name} ( LIKE deliveries INCLUDING ALL );
      """
    ]
  end

  @doc """
  Builds a query to drop a table for the given topic name.
  """
  @impl true
  def drop_queries(topic_or_name) do
    [
      """
      DROP TABLE IF EXISTS #{table_name(topic_or_name)};
      """
    ]
  end

  @doc """
  Creates the table for the topic table
  """
  @impl true
  def create_table!(topic_or_name) do
    create_queries(topic_or_name)
    |> Enum.each(fn query -> Ecto.Adapters.SQL.query!(Repo, query, []) end)
  end

  @doc """
  Drops the table for the topic table
  """
  @impl true
  def drop_table!(topic_or_name) do
    drop_queries(topic_or_name)
    |> Enum.each(fn query -> Ecto.Adapters.SQL.query!(Repo, query, []) end)
  end
end
