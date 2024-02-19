defmodule ER.Repo.Migrations.AddEventsToTopic do
  use Ecto.Migration

  def change do
    alter table(:topics, primary_key: false) do
      add :event_configs, {:array, :map}, default: []
    end
  end
end
