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
             :config
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
    belongs_to :topic, Topic, foreign_key: :topic_name, references: :name, type: :string
    field :topic_identifier, :string

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
      :topic_identifier,
      :subscription_type
    ])
    |> validate_required([:name, :topic_name, :push, :subscription_type])
    |> validate_length(:name, min: 3, max: 255)
    |> unique_constraint(:name)
    |> ER.Schema.normalize_name()
    |> assoc_constraint(:topic)
    |> validate_inclusion(:subscription_type, ["s3", "webhook", "websocket"])
  end
end
