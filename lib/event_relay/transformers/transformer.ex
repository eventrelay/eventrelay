defmodule ER.Transformers.Transformer do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Sources.Source
  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transformers" do
    field :script, :string
    belongs_to(:source, Source)
    field(:type, Ecto.Enum, values: [:lua, :liquid])
    field(:return_type, Ecto.Enum, values: [:map])
    field :query, :string
    timestamps()
  end

  @doc false
  def changeset(transformer, attrs) do
    transformer
    |> cast(attrs, [:script, :source_id, :return_type, :query])
    |> validate_required([:script, :return_type])
  end

  def matches?(%Transformer{query: nil}, _data), do: true

  def matches?(%Transformer{query: query}, data) do
    if Flamel.present?(query), do: Predicated.test(query, data), else: true
  end
end
