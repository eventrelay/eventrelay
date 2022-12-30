defmodule ER.Ecto do
  @moduledoc """
  Ecto heplper functions
  """

  defp prettify({field_name, messages}) when is_list(messages) do
    human_field_name =
      field_name
      |> Atom.to_string()
      |> String.replace("_", " ")
      |> String.capitalize()

    Enum.reduce(messages, [], fn message, acc ->
      [human_field_name <> " " <> message | acc]
    end)
  end

  def changeset_errors_to_list(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", ER.to_string(value))
      end)
    end)
    |> Enum.map(&prettify/1)
    |> List.flatten()
  end

  def changeset_errors_to_string(changeset) do
    changeset_errors_to_list(changeset)
    |> Enum.join(", ")
  end
end
