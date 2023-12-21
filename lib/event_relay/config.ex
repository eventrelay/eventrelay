defmodule ER.Config do
  import Ecto.Changeset

  def decode_config(%Ecto.Changeset{changes: %{config_json: context}} = changeset) do
    case Jason.decode(context) do
      {:ok, decoded} ->
        changeset
        |> put_change(:config, decoded)

      {:error, _} ->
        changeset
        |> add_error(:config, "is invalid JSON")
    end
  end

  def decode_config(changeset) do
    changeset
  end

  def config_json(schema) do
    Jason.encode!(schema.config)
  end
end
