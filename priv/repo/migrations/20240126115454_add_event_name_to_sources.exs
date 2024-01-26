defmodule ER.Repo.Migrations.AddEventNameToSources do
  use Ecto.Migration

  def change do
    alter table(:sources, primary_key: false) do
      add(:event_name, :string)
    end
  end
end
