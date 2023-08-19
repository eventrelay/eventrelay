defmodule ER.Validators do
  import Ecto.Changeset, only: [get_field: 2, add_error: 3]

  def validate_at_least_one_required(changeset, fields) when is_list(fields) do
    values =
      Enum.map(fields, fn field ->
        get_field(changeset, field)
      end)
      |> Enum.reject(&is_nil/1)

    if ER.empty?(values) do
      add_error(changeset, :field_or_field_path, "can't be blank")
    else
      changeset
    end
  end
end
