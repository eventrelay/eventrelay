defmodule ER.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset
  @behaviour ER.TopicTable

  alias ER.Events.Topic
  alias ER.Repo

  @typedoc """
  The Event schema
  """
  @type t :: %__MODULE__{
          id: binary(),
          topic_name: String.t(),
          topic_identifier: String.t(),
          data_json: String.t(),
          data: map(),
          user_id: integer(),
          anonymous_id: String.t(),
          occurred_at: DateTime.t(),
          offset: integer(),
          source: String.t(),
          context: map(),
          errors: list(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @derive {Jason.Encoder,
           only: [
             :id,
             :topic_name,
             :topic_identifier,
             :name,
             :data,
             :user_id,
             :anonymous_id,
             :occurred_at,
             :offset,
             :source,
             :context,
             :errors
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "events" do
    field :errors, {:array, :string}
    field :context, :map
    field :context_json, :string, virtual: true
    field :data, :map
    field :data_json, :string, virtual: true
    field :name, :string
    field :topic_identifier, :string
    field :user_id, :string
    field :anonymous_id, :string
    field :occurred_at, :utc_datetime
    field :offset, :integer, read_after_writes: true
    field :source, :string
    belongs_to :topic, Topic, foreign_key: :topic_name, references: :name, type: :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :name,
      :offset,
      :source,
      :occurred_at,
      :context,
      :context_json,
      :data,
      :data_json,
      :topic_name,
      :topic_identifier,
      :user_id,
      :anonymous_id
    ])
    |> decode_context()
    |> decode_data()
    # |> decode_occurred_at()
    |> assoc_constraint(:topic)
    |> foreign_key_constraint(:topic_name, name: :events_topic_name_fkey)
    |> validate_required([
      :name,
      :source,
      :data,
      :topic_name
    ])
  end

  def decode_context(%Ecto.Changeset{changes: %{context_json: context}} = changeset) do
    changeset
    |> put_change(:context, Jason.decode!(context))
  end

  def decode_context(changeset) do
    changeset
  end

  def decode_data(%Ecto.Changeset{changes: %{data_json: data}} = changeset) do
    case Jason.decode(data) do
      {:ok, decoded} ->
        changeset
        |> put_change(:data, decoded)

      {:error, _} ->
        changeset
        |> add_error(:data, "is invalid JSON")
    end
  end

  def decode_data(changeset) do
    changeset
  end

  def decode_occurred_at(%Ecto.Changeset{changes: %{occurred_at: occurred_at}} = changeset) do
    # handle the default GRPC value for a string
    cond do
      occurred_at == "" ->
        changeset

      occurred_at == nil ->
        changeset

      true ->
        changeset
    end

    if occurred_at == "" do
      changeset
      |> put_change(:occurred_at, nil)
    else
      case DateTime.from_iso8601(occurred_at) do
        {:ok, datetime, _} ->
          changeset
          |> put_change(:occurred_at, datetime)

        {:error, _} ->
          changeset
          |> add_error(:occurred_at, "is invalid ISO8601 datetime")
      end
    end
  end

  def decode_occurred_at(changeset) do
    changeset
  end

  def context_json(event) do
    Jason.encode!(event.context)
  end

  def data_json(event) do
    Jason.encode!(event.data)
  end

  @doc """
  Changes the source in the struct to the topic table name
  """
  @impl ER.TopicTable
  def put_ecto_source(%__MODULE__{} = event, topic_name) do
    source = table_name(topic_name)

    Ecto.put_meta(event,
      source: source,
      state: :built
    )
  end

  @doc """
  Creates a table name for the given topic name.

  Examples:

    iex> ER.Events.Event.table_name("users")
    "users_events"

    iex> topic = %ER.Events.Topic{name: "test"}
    iex> ER.Events.Event.table_name(topic)
    "test_events"
  """
  @impl ER.TopicTable
  def table_name(%Topic{} = topic) do
    table_name(topic.name)
  end

  def table_name(topic_name) do
    topic_name <> "_events"
  end

  @doc """
  Builds a query to create a table for the given topic name.
  """
  @impl ER.TopicTable
  def create_queries(topic_or_name) do
    table_name = table_name(topic_or_name)
    # TODO: add sequence for offset to new table
    # CREATE SEQUENCE table_name_id_seq;

    # CREATE TABLE table_name (
    #     id integer NOT NULL DEFAULT nextval('table_name_id_seq')
    # );

    # ALTER SEQUENCE table_name_id_seq
    # OWNED BY table_name.id;
    # ALTER TABLE products ALTER COLUMN price SET DEFAULT 7.77;
    [
      """
      CREATE TABLE IF NOT EXISTS #{table_name} ( LIKE events INCLUDING ALL );
      """,
      """
      ALTER TABLE #{table_name} ADD CONSTRAINT "#{table_name}_topic_name_fkey" FOREIGN KEY (topic_name) REFERENCES topics(name);
      """
    ]
  end

  @doc """
  Builds a query to drop a table for the given topic name.
  """
  @impl ER.TopicTable
  def drop_queries(topic_or_name) do
    [
      """
      DROP TABLE IF EXISTS #{table_name(topic_or_name)};
      """
    ]
  end

  @doc """
  Creates the table for the event topic table
  """
  @impl ER.TopicTable
  def create_table!(topic_or_name) do
    create_queries(topic_or_name)
    |> Enum.each(fn query -> Ecto.Adapters.SQL.query!(Repo, query, []) end)
  end

  @doc """
  Drops the table for the event topic table
  """
  @impl ER.TopicTable
  def drop_table!(topic_or_name) do
    drop_queries(topic_or_name)
    |> Enum.each(fn query -> Ecto.Adapters.SQL.query!(Repo, query, []) end)
  end
end
