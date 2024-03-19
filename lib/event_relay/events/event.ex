defmodule ER.Events.Event do
  use ER.Ecto.Schema
  import Ecto.Changeset
  @behaviour ER.TopicTable

  alias ER.Events.Topic
  alias ER.Repo
  alias __MODULE__

  @typedoc """
  Event name
  """
  @type name() :: String.t()

  @typedoc """
  The Event schema
  """
  @type t :: %__MODULE__{
          id: binary(),
          name: name(),
          topic_name: String.t(),
          topic_identifier: String.t(),
          data_json: String.t(),
          data: map(),
          data_schema_json: String.t(),
          data_schema: map(),
          user_key: integer(),
          anonymous_key: String.t(),
          occurred_at: DateTime.t(),
          offset: integer(),
          source: String.t(),
          verified: String.t(),
          context: map(),
          errors: list(),
          trace_key: binary(),
          reference_key: binary(),
          group_key: binary(),
          prev_id: binary(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t(),
          available_at: DateTime.t()
        }

  @derive {Jason.Encoder,
           only: [
             :id,
             :topic_name,
             :topic_identifier,
             :name,
             :data,
             :data_schema,
             :user_key,
             :anonymous_key,
             :occurred_at,
             :available_at,
             :offset,
             :source,
             :verified,
             :context,
             :errors,
             :group_key,
             :reference_key,
             :trace_key,
             :prev_id
           ]}

  @virtual_fields [:data_json, :data_schema_json, :context_json]

  schema "events" do
    field :name, :string
    field :errors, {:array, :string}
    field :context, :map
    field :context_json, :string, virtual: true
    field :data, :map
    field :data_json, :string, virtual: true
    field :data_schema, :map
    field :data_schema_json, :string, virtual: true
    field :topic_identifier, :string
    field :user_key, :string
    field :anonymous_key, :string
    field :occurred_at, :utc_datetime
    field :available_at, :utc_datetime
    field :offset, :integer, read_after_writes: true
    field :source, :string
    field :verified, :boolean, default: false

    # This can be used to segment events. For instance, it can store a tenant, account, or organization id
    field :group_key, :string

    # This can be used to hold an id to reference some external resource. It provides another way to segment events. For instance, all events associated to shipment, order, etc.
    field :reference_key, :string

    # This can be used for debugging scenarios. For instance, it can store a request id, etc
    field :trace_key, :string

    # An array of all the destinations that have locked this event. This is used with queued events to ensure deliver once functionality through the API
    field :destination_locks, {:array, :binary_id}, default: []

    # The id of the event that triggered this event
    field :prev_id, :binary_id

    belongs_to :topic, Topic, foreign_key: :topic_name, references: :name, type: :string

    timestamps()
  end

  def apply_defaults(attrs) do
    attrs
    |> put_datetime_if_empty(:occurred_at)
    |> put_datetime_if_empty(:available_at)
  end

  def prepare_for_batched_insert(attrs) do
    attrs
    |> drop_virtual_fields()
    |> ensure_id()
  end

  def ensure_id(attrs) do
    value = attrs[:id]

    value =
      if ER.empty?(value) do
        Uniq.UUID.uuid7()
      else
        value
      end

    Map.put(attrs, :id, value)
  end

  def drop_virtual_fields(attrs) do
    Map.drop(attrs, @virtual_fields)
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

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :name,
      :offset,
      :source,
      :group_key,
      :reference_key,
      :trace_key,
      :occurred_at,
      :context,
      :context_json,
      :data,
      :data_json,
      :topic_name,
      :topic_identifier,
      :user_key,
      :anonymous_key,
      :destination_locks,
      :data_schema,
      :data_schema_json,
      :verified,
      :prev_id,
      :available_at
    ])
    |> decode_context()
    |> decode_data()
    |> decode_data_schema()
    |> validate_event_data_schema()
    |> validate_data_schema()
    |> assoc_constraint(:topic)
    |> foreign_key_constraint(:topic_name, name: :events_topic_name_fkey)
    |> validate_required([
      :name,
      :source,
      :data,
      :topic_name
    ])
  end

  def validate_event_data_schema(changeset) do
    topic_name = get_field(changeset, :topic_name)
    event_name = get_field(changeset, :name)

    event_schema =
      ER.Events.TopicCache.fetch_event_schema_for_topic_and_event(topic_name, event_name)

    if event_schema do
      validate_change(changeset, :data, fn _, data ->
        validate_schema(event_schema, data)
      end)
    else
      changeset
    end
  end

  def validate_data_schema(
        %Ecto.Changeset{changes: %{data_schema_json: data}} =
          changeset
      )
      when not is_nil(data) do
    data_schema_valid?(changeset)
  end

  def validate_data_schema(%Ecto.Changeset{changes: %{data_schema: data}} = changeset)
      when not is_nil(data) do
    data_schema_valid?(changeset)
  end

  def validate_data_schema(changeset) do
    changeset
  end

  defp data_schema_valid?(changeset) do
    get_field(changeset, :data_schema)
    |> then(fn
      nil ->
        changeset

      data_schema ->
        validate_change(changeset, :data, fn _, data ->
          validate_schema(data_schema, data)
        end)
    end)
  end

  defp validate_schema(data_schema, data) do
    case ExJsonSchema.Validator.validate(data_schema, data) do
      :ok ->
        []

      {:error, errors} ->
        error_messages = Enum.map_join(errors, ", ", fn {error, _} -> error end)
        [{:data, "does not validate against the schema because of errors: #{error_messages}"}]
    end
  end

  def decode_context(%Ecto.Changeset{changes: %{context_json: context}} = changeset) do
    case Jason.decode(context) do
      {:ok, decoded} ->
        changeset
        |> put_change(:context, decoded)

      {:error, _} ->
        changeset
        |> add_error(:context, "is invalid JSON")
    end
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

  def decode_data_schema(%Ecto.Changeset{changes: %{data_schema_json: data}} = changeset) do
    case Jason.decode(data) do
      {:ok, decoded} ->
        changeset
        |> put_change(:data_schema, decoded)

      {:error, _} ->
        changeset
        |> add_error(:data_schema, "is invalid JSON")
    end
  end

  def decode_data_schema(changeset) do
    changeset
  end

  def decode_datetime_at(changeset, field) do
    field = Flamel.to_atom(field)
    value = get_change(changeset, field)
    # handle the default GRPC value for a string
    if value in ["", nil] do
      changeset
      |> put_change(field, nil)
    else
      case Flamel.Moment.to_datetime(value) do
        nil ->
          changeset
          |> add_error(field, "is invalid ISO8601 datetime")

        datetime ->
          changeset
          |> put_change(field, datetime)
      end
    end
  end

  def decode_datetime_at(changeset) do
    changeset
  end

  def context_json(event) do
    Jason.encode!(event.context)
  end

  def data_json(event) do
    Jason.encode!(event.data)
  end

  def data_schema_json(event) do
    Jason.encode!(event.data_schema)
  end

  @doc """
  JSON encode an event
  """
  def json_encode!(event) do
    Jason.encode!(event)
  end

  @doc """
  Produce a signature for an event
  """

  def signature(value, opts \\ [])

  def signature(value, opts) when is_binary(value) do
    opts = Keyword.put(opts, :value, value)
    ER.Auth.hmac(opts)
  end

  def signature(%Event{} = event, opts) do
    event |> json_encode!() |> signature(opts)
  end

  @fields_to_drop [:__meta__, :destination_locks, :topic]

  def to_map(%Event{} = event, additional_fields_to_drop \\ []) do
    Map.from_struct(event)
    |> Map.drop(@fields_to_drop ++ additional_fields_to_drop)
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
    String.downcase(topic_name <> "_events")
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
