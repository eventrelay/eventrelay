defmodule ER.Pruners.Pruner do
  use ER.Ecto.Schema
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
  schema "pruners" do
    field :name, :string
    field :config, :map, default: %{}
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

  def base_config(:count) do
    %{
      "max_count" => 10_000
    }
  end

  def base_config(:time) do
    %{
      "max_age" => 3_600
    }
  end
end
