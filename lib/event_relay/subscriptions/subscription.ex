defmodule ER.Subscriptions.Subscription do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Events.Topic

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :topic_name,
             :topic_identifier,
             :offset,
             :ordered,
             :subscription_type,
             :push,
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
    field :subscription_type, :string
    field :push, :boolean, default: true
    field :paused, :boolean, default: false
    field :config, :map, default: %{}
    field :config_json, :string, virtual: true
    field :topic_identifier, :string
    field :group_key, :string
    field :signing_secret, :string

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
      :push,
      :ordered,
      :paused,
      :config,
      :config_json,
      :topic_identifier,
      :subscription_type,
      :group_key,
      :signing_secret
    ])
    |> validate_required([:name, :topic_name, :push, :subscription_type])
    |> validate_length(:name, min: 3, max: 255)
    |> unique_constraint(:name)
    |> decode_config()
    |> put_signing_secret()
    |> ER.Schema.normalize_name()
    |> assoc_constraint(:topic)
    |> validate_inclusion(:subscription_type, ["s3", "webhook", "websocket", "api"])
  end

  def decode_config(%Ecto.Changeset{changes: %{config_json: context}} = changeset) do
    case Jason.decode(context) do
      {:ok, decoded} ->
        changeset
        |> put_change(:config, decoded)

      {:error, _} ->
        changeset
        |> add_error(:config, "is invalid JSON")
    end
  end

  def decode_config(changeset) do
    changeset
  end

  def config_json(subscription) do
    Jason.encode!(subscription.config)
  end

  def put_signing_secret(changeset) do
    # we only want to add the signing_secret if there is not one
    if changeset.data.signing_secret == nil do
      put_change(changeset, :signing_secret, ER.Auth.generate_secret())
    else
      changeset
    end
  end

  def api?(subscription) do
    subscription.push == false && subscription.subscription_type == "api"
  end

  def websocket?(subscription) do
    subscription.push && subscription.subscription_type == "websocket"
  end

  def push_to_websocket?(subscription) do
    websocket?(subscription) &&
      subscription.paused != true && ER.Container.channel_cache().any_sockets?(subscription.id)
  end

  def webhook?(subscription) do
    subscription.push && subscription.subscription_type == "webhook"
  end

  def push_to_webhook?(subscription) do
    webhook?(subscription) && subscription.paused != true
  end

  def s3?(subscription) do
    subscription.push && subscription.subscription_type == "s3"
  end

  def push_to_s3?(subscription) do
    s3?(subscription) &&
      subscription.paused != true
  end
end
