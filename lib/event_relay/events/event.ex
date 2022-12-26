defmodule ER.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  alias ER.Events.Topic

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "events" do
    field :context, :map
    field :context_json, :string, virtual: true
    field :data, :map
    field :data_json, :string, virtual: true
    field :name, :string
    field :topic_identifier, :string
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
      :topic_identifier
    ])
    |> put_data_and_context()
    |> validate_required([
      :name,
      :source,
      :data,
      :topic_name
    ])
  end

  def put_data_and_context(
        %Ecto.Changeset{changes: %{data_json: data, context_json: context}} = changeset
      ) do
    changeset
    |> put_change(:data, Jason.decode!(data))
    |> put_change(:context, Jason.decode!(context))
  end

  def put_data_and_context(changeset), do: changeset

  def context_json(event) do
    Jason.encode!(event.context)
  end

  def data_json(event) do
    Jason.encode!(event.data)
  end
end
