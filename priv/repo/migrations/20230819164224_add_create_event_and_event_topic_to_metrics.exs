defmodule ER.Repo.Migrations.AddCreateEventAndEventTopicToMetrics do
  use Ecto.Migration

  def change do
    alter table(:metrics, primary_key: false) do
      add :produce_update_event, :boolean, default: true
    end
  end
end
