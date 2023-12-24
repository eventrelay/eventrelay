defmodule ER.Transformers.Transformer do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Sources.Source

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transformers" do
    field :script, :string
    belongs_to(:source, Source)
    field(:return_type, Ecto.Enum, values: [:map])

    timestamps()
  end

  @doc false
  def changeset(transformer, attrs) do
    transformer
    |> cast(attrs, [:script, :source_id, :return_type])
    |> validate_required([:script, :return_type])
  end
end
