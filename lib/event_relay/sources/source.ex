defmodule ER.Sources.Source do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Transformers.Transformer
  alias ER.Events.Topic
  import ER.Config
  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sources" do
    field :config, :map, default: %{}
    field :config_json, :string, virtual: true
    # field(:type, Ecto.Enum, values: [:google_pubsub])
    field(:type, Ecto.Enum, values: [:webhook, :standard_webhook])
    # TODO: rething the Transformers
    has_many(:transformers, Transformer)
    belongs_to :topic, Topic, foreign_key: :topic_name, references: :name, type: :string
    field :source, :string
    field :event_name, :string
    field :key, :string
    field :secret, :string

    timestamps()
  end

  @doc false
  def create_changeset(source, attrs) do
    immutable_attrs = %{
      "key" => ER.Auth.generate_key(),
      "secret" => ER.Auth.generate_secret()
    }

    source
    |> cast(Map.merge(attrs, immutable_attrs), [
      :type,
      :config,
      :topic_name,
      :source,
      :key,
      :secret
    ])
    |> validate_required([:type, :topic_name, :source, :key, :secret])
    |> decode_config()
  end

  def changeset(source, attrs) do
    source
    |> cast(attrs, [:type, :config, :topic_name, :source])
    |> validate_required([:type, :topic_name, :source])
    |> decode_config()
  end

  def get_broadway_producer(%Source{type: :google_pubsub}) do
    BroadwayCloudPubSub.Producer
  end

  def get_broadway_producer(_) do
    nil
  end

  def start_source(%Source{type: :google_pubsub} = source) do
    ER.Sources.GooglePubSub.start_link(source: source)
  end

  def start_source(_) do
    :noop
  end

  defimpl ER.Transformers.TransformationContext do
    def build(source) do
      %{
        "topic_name" => source.topic_name,
        "source" => source.source,
        "source_type" => Flamel.to_string(source.type),
        "source_config" => source.config
      }
    end
  end
end
