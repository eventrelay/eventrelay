defmodule ER.Events.EventConfig do
  @moduledoc """
  Schema to store configuration related to events in a topic
  """
  use Ecto.Schema
  alias ER.Events.Event

  @typedoc """
  The EventConfig schema.
  """
  @type t :: %__MODULE__{
          name: Event.name()
        }

  embedded_schema do
    field :name
    field :schema
  end
end
