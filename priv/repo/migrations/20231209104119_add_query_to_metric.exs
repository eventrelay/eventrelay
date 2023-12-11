defmodule ER.Repo.Migrations.AddQueryToMetric do
  use Ecto.Migration

  def change do
    alter table(:metrics, primary_key: false) do
      add :query, :text
    end
  end
end
