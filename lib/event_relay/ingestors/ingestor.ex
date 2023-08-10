defmodule ER.Ingestors.Ingestor do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Transformers.Transformer
  alias ER.Events.Topic
  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ingestors" do
    field :config, :map
    field(:type, Ecto.Enum, values: [:google_pubsub])
    has_one(:transformer, Transformer)
    belongs_to :topic, Topic, foreign_key: :topic_name, references: :name, type: :string
    field :source, :string

    timestamps()
  end

  @doc false
  def changeset(ingestor, attrs) do
    ingestor
    |> cast(attrs, [:type, :config, :topic_name, :source])
    |> validate_required([:type, :topic_name, :source])
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
