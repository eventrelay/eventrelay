defmodule ER.Events.EventFilter do
  use Ecto.Schema

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

    field :comparison, Ecto.Enum, values: [:equal, :not_equal, :like, :ilike]
    field :value, :string
    field :field_path, :string
  end
end
