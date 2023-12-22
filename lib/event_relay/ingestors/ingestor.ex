defmodule ER.Ingestors.Ingestor do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Transformers.Transformer
  alias ER.Events.Topic
  import ER.Config
  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ingestors" do
    field :config, :map, default: %{}
    field :config_json, :string, virtual: true
    # field(:type, Ecto.Enum, values: [:google_pubsub])
    field(:type, Ecto.Enum, values: [:webhook])
    # TODO: rething the Transformers
    has_one(:transformer, Transformer)
    belongs_to :topic, Topic, foreign_key: :topic_name, references: :name, type: :string
    field :source, :string
    field :key, :string
    field :secret, :string

    timestamps()
  end

  @doc false
  def create_changeset(ingestor, attrs) do
    immutable_attrs = %{
      key: ER.Auth.generate_key(),
      secret: ER.Auth.generate_secret()
    }

    ingestor
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

  def changeset(ingestor, attrs) do
    ingestor
    |> cast(attrs, [:type, :config, :topic_name, :source])
    |> validate_required([:type, :topic_name, :source])
    |> decode_config()
  end

  def get_broadway_producer(%Ingestor{type: :google_pubsub}) do
    BroadwayCloudPubSub.Producer
  end

  def get_broadway_producer(_) do
    nil
  end

  def start_ingestor(%Ingestor{type: :google_pubsub} = ingestor) do
    ER.Ingestors.GooglePubSub.start_link(ingestor: ingestor)
  end

  def start_ingestor(_) do
    :noop
  end

  def build_context(%Ingestor{type: :google_pubsub} = ingestor) do
    # TODO: move topic_name and source info a context map on the ingester
    %{"topic_name" => ingestor.topic_name, "source" => ingestor.source}
  end

  def build_context(_) do
    %{}
  end
end
