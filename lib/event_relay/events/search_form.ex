defmodule ER.Events.SearchForm do
  use ER.Ecto.Schema

  schema "" do
    field :query, :string
  end
end
