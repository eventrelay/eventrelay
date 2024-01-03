defmodule ER.Repo.Migrations.AddAvailableAtToEvents do
  use Ecto.Migration

  def change do
    alter table(:events, primary_key: false) do
      add :available_at, :utc_datetime
    end

    alter table(:dead_letter_events, primary_key: false) do
      add :available_at, :utc_datetime
    end
  end
end
