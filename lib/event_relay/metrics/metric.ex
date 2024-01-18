defmodule ER.Metrics.Metric do
  use Ecto.Schema
  import Ecto.Changeset

  alias ER.Events.Topic

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "metrics" do
    field :field_path, :string
    field :name, :string
    field :produce_update_event, :boolean, default: true
    field :type, Ecto.Enum, values: [:sum, :avg, :min, :max, :count]
    field :topic_identifier, :string
    field :query, :string
    belongs_to :topic, Topic, foreign_key: :topic_name, references: :name, type: :string

    timestamps()
  end

  @doc false
  def changeset(metric, attrs) do
    metric
    |> cast(attrs, [
      :name,
      :field_path,
      :type,
      :topic_name,
      :topic_identifier,
      :produce_update_event,
      :query
    ])
    |> Flamel.Ecto.Validators.validate_required_if(
      :field_path,
      fn cs ->
        type = get_field(cs, :type)
        type not in [:count]
      end,
      message: "field path is required"
    )
    |> validate_required([:name, :type, :topic_name])
  end
end
