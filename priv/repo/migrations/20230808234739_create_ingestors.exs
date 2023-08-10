defmodule ER.Repo.Migrations.CreateIngestors do
  use Ecto.Migration

  def change do
    create table(:ingestors, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :config, :map

      timestamps()
    end
  end
end
