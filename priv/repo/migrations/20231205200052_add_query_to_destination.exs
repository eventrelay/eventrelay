defmodule ER.Repo.Migrations.AddQueryToDestination do
  use Ecto.Migration

  def change do
    alter table(:destinations, primary_key: false) do
      add :query, :text
    end
  end
end
