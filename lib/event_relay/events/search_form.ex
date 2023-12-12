defmodule ER.Events.SearchForm do
  use Ecto.Schema

  schema "" do
    field :query, :string
  end
end
