defmodule ER.Schema do
  import Ecto.Changeset, only: [put_change: 3]

  def normalize_name(%Ecto.Changeset{changes: %{name: name}} = changeset) do
    name =
      name
      |> String.replace(~r/[^[:alnum:]\w]/, "_")
      |> String.downcase()

    put_change(changeset, :name, name)
  end

  def normalize_name(changeset) do
    changeset
  end
end
