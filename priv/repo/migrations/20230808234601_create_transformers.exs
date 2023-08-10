defmodule ER.Repo.Migrations.CreateTransformers do
  use Ecto.Migration

  def change do
    create table(:transformers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :script, :text

      timestamps()
    end
  end
end
