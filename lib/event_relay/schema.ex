defmodule ER.Schema do
  import Ecto.Changeset, only: [put_change: 3]

  def normalize_name(%Ecto.Changeset{changes: %{name: name}} = changeset) do
    changeset
    |> put_change(:name, String.replace(name, ~r/[^[:alnum:]\w]/, "_"))
  end

  def normalize_name(changeset) do
    changeset
  end
end
