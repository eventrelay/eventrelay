defmodule ER.Metrics.Metric do
  use Ecto.Schema
  import Ecto.Changeset

  alias ER.Events.{EventFilter, Topic}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "metrics" do
    field :field_path, :string
    field :name, :string
    field :type, Ecto.Enum, values: [:sum, :avg, :min, :max, :count]
    belongs_to :topic, Topic, foreign_key: :topic_name, references: :name, type: :string
    field :topic_identifier, :string
    embeds_many :filters, EventFilter

    timestamps()
  end

  @doc false
  def changeset(metric, attrs) do
    metric
    |> cast(attrs, [:name, :field_path, :type])
    |> cast_embed(:filters)
    |> validate_required([:name, :field_path, :type])
  end
end
