defmodule ER.Filter do
  use Ecto.Schema
  import Ecto.Changeset
  import ER.Validators, only: [validate_at_least_one_required: 2]
  import ER

  embedded_schema do
    field :field, :string
    field :field_path, :string
    field :comparison, Ecto.Enum, values: [:equal, :not_equal, :like, :ilike, :in]
    field :value, :string
  end

  def changeset(filter, attrs) do
    filter
    |> cast(attrs, [:field, :field_path, :comparison, :value])
    |> validate_required([:comparison, :value])
    |> validate_at_least_one_required([:field, :field_path])
  end

  def translate_comparison(comparison) do
    case to_string(comparison) do
      "equal" ->
        "="

      "not_equal" ->
        "!="

      c ->
        c
    end
  end

  def translate(filters) do
    filters
    |> Enum.reduce([], fn filter, acc ->
      transformed_filter =
        filter
        |> Map.from_struct()
        |> Map.update!(:comparison, &translate_comparison/1)
        |> atomize_map()

      [transformed_filter | acc]
    end)
  end

  defmodule BadFieldError do
    defexception message: "field does not exist"
  end
end
