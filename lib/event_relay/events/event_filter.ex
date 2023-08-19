defmodule ER.Events.EventFilter do
  use Ecto.Schema
  import Ecto.Changeset
  import ER.Validators, only: [validate_at_least_one_required: 2]

  embedded_schema do
    field :field, Ecto.Enum,
      values: [
        :name,
        :reference_key,
        :group_key,
        :trace_key,
        :source,
        :user_id,
        :anonymous_id,
        :topic_identifier,
        :data,
        :context
      ]

    field :comparison, Ecto.Enum, values: [:equal, :not_equal, :like, :ilike, :in]
    field :value, :string
    field :field_path, :string
  end

  def changeset(filter, attrs) do
    filter
    |> cast(attrs, [:field, :field_path, :comparison, :value])
    |> validate_required([:comparison, :value])
    |> validate_at_least_one_required([:field, :field_path])
  end
end
