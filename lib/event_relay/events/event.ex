defmodule ER.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  alias ER.Events.Topic

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

    timestamps()
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
    |> decode_occurred_at()
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
end
