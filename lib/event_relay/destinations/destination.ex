defmodule ER.Destinations.Destination do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Events.Topic
  import ER.Config

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :topic_name,
             :topic_identifier,
             :offset,
             :ordered,
             :destination_type,
             :paused,
             :config,
             :group_key
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "destinations" do
    field :name, :string
    field :offset, :integer
    field :ordered, :boolean, default: false
    field(:destination_type, Ecto.Enum, values: [:api, :webhook, :websocket, :file, :topic])
    field :paused, :boolean, default: false
    field :config, :map, default: %{}
    field :config_json, :string, virtual: true
    field :topic_identifier, :string
    field :group_key, :string
    field :signing_secret, :string
    field :query, :string

    belongs_to :topic, Topic, foreign_key: :topic_name, references: :name, type: :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(destination, attrs) do
    destination
    |> cast(attrs, [
      :name,
      :offset,
      :topic_name,
      :ordered,
      :paused,
      :config,
      :config_json,
      :topic_identifier,
      :destination_type,
      :group_key,
      :signing_secret,
      :query
    ])
    |> validate_required([:name, :topic_name, :destination_type])
    |> validate_length(:name, min: 3, max: 255)
    |> unique_constraint(:name)
    |> decode_config()
    |> put_signing_secret()
    |> ER.Schema.normalize_name()
    |> assoc_constraint(:topic)
    |> validate_inclusion(:destination_type, [:file, :webhook, :websocket, :api, :topic])
  end

  def put_signing_secret(changeset) do
    # we only want to add the signing_secret if there is not one
    if changeset.data.signing_secret == nil do
      put_change(changeset, :signing_secret, ER.Auth.generate_secret())
    else
      changeset
    end
  end

  def api?(%{destination_type: :api}), do: true
  def api?(_), do: false

  def websocket?(%{destination_type: :websocket}), do: true
  def websocket?(_), do: false

  def webhook?(%{destination_type: :webhook}), do: true
  def webhook?(_), do: false

  def s3?(%{destination_type: :s3}), do: true
  def s3?(_), do: false

  def topic?(%{destination_type: :topic}), do: true
  def topic?(_), do: false

  def matches?(%{query: nil}, _event) do
    true
  end

  def matches?(%{query: query}, event) do
    event =
      Map.from_struct(event) |> Map.drop([:topic, :__meta__]) |> ER.atomize_map()

    Predicated.test(query, event)
  end
end
