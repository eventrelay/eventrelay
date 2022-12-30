defmodule ER.Schema do
  import Ecto.Changeset, only: [put_change: 3]

  def normalize_name(changeset) do
    changeset
    |> put_change(:name, String.replace(changeset.changes.name, " ", "_"))
  end
end
