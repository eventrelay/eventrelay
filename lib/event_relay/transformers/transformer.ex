defmodule ER.Transformers.Transformer do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Destinations.Destination
  alias ER.Sources.Source
  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transformers" do
    field :script, :string
    belongs_to(:source, Source)
    belongs_to(:destination, Destination)
    field(:type, Ecto.Enum, values: [:lua, :liquid])
    field(:return_type, Ecto.Enum, values: [:map])
    field :query, :string
    timestamps()
  end

  @doc false
  def changeset(transformer, attrs) do
    transformer
    |> cast(attrs, [:script, :source_id, :return_type, :query])
    |> Flamel.Ecto.Validators.validate_at_least_one_required(
      [:destination_id, :source_id],
      "must select either a source or destination"
    )
    |> validate_required([:script, :return_type])
  end

  def matches?(%Transformer{query: nil}, _data), do: false

  def matches?(%Transformer{query: query}, data) do
    if Flamel.present?(query), do: Predicated.test(query, data), else: false
  end
end
