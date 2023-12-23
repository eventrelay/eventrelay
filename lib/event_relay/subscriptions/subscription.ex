defmodule ER.Subscriptions.Subscription do
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
             :subscription_type,
             :paused,
             :config,
             :group_key
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "subscriptions" do
    field :name, :string
    field :offset, :integer
    field :ordered, :boolean, default: false
    field(:subscription_type, Ecto.Enum, values: [:api, :webhook, :websocket, :s3, :topic])
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
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [
      :name,
      :offset,
      :topic_name,
      :ordered,
      :paused,
      :config,
      :config_json,
      :topic_identifier,
      :subscription_type,
      :group_key,
      :signing_secret,
      :query
    ])
    |> validate_required([:name, :topic_name, :subscription_type])
    |> validate_length(:name, min: 3, max: 255)
    |> unique_constraint(:name)
    |> decode_config()
    |> put_signing_secret()
    |> ER.Schema.normalize_name()
    |> assoc_constraint(:topic)
    |> validate_inclusion(:subscription_type, [:s3, :webhook, :websocket, :api, :topic])
  end

  def put_signing_secret(changeset) do
    # we only want to add the signing_secret if there is not one
    if changeset.data.signing_secret == nil do
      put_change(changeset, :signing_secret, ER.Auth.generate_secret())
    else
      changeset
    end
  end

  def api?(%{subscription_type: "api"}), do: true
  def api?(_), do: false

  def websocket?(%{subscription_type: "websocket"}), do: true
  def websocket?(_), do: false

  def webhook?(%{subscription_type: "webhook"}), do: true
  def webhook?(_), do: false

  def s3?(%{subscription_type: "s3"}), do: true
  def s3?(_), do: false

  def topic?(%{subscription_type: "topic"}), do: true
  def topic?(_), do: false

  def push_to_websocket?(subscription) do
    websocket?(subscription) &&
      subscription.paused != true && ER.Container.channel_cache().any_sockets?(subscription.id)
  end

  def push_to_webhook?(subscription) do
    webhook?(subscription) && subscription.paused != true
  end

  def push_to_s3?(subscription) do
    s3?(subscription) &&
      subscription.paused != true
  end

  def push_to_topic?(subscription) do
    topic?(subscription) &&
      subscription.paused != true
  end

  def matches?(%{query: nil}, _event) do
    true
  end

  def matches?(%{query: query}, event) do
    event =
      Map.from_struct(event) |> Map.drop([:topic, :__meta__]) |> ER.atomize_map()

    Predicated.test(query, event)
  end
end
