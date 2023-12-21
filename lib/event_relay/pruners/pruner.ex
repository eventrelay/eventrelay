defmodule ER.Pruners.Pruner do
  use Ecto.Schema
  import Ecto.Changeset
  import ER.Config
  alias ER.Events.Topic

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :topic_name,
             :query,
             :config,
             :type
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "pruners" do
    field :name, :string
    field :config, :map
    field :config_json, :string, virtual: true
    field :query, :string
    field(:type, Ecto.Enum, values: [:time, :count])
    belongs_to :topic, Topic, foreign_key: :topic_name, references: :name, type: :string

    timestamps()
  end

  @doc false
  def changeset(pruner, attrs) do
    pruner
    |> cast(attrs, [:name, :config, :query, :type, :topic_name, :config_json])
    |> validate_required([:name, :type, :topic_name])
    |> decode_config()
  end
end
