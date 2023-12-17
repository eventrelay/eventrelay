defmodule ER.Repo.Migrations.AddDataSchemaToEvents do
  use Ecto.Migration

  def change do
    alter table(:events, primary_key: false) do
      add :data_schema, :map
    end

    alter table(:dead_letter_events, primary_key: false) do
      add :data_schema, :map
    end
  end
end
