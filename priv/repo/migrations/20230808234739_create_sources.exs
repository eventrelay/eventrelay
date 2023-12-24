defmodule ER.Repo.Migrations.CreateSources do
  use Ecto.Migration

  def change do
    create table(:sources, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :config, :map

      timestamps()
    end
  end
end
