defmodule ER.Repo.Migrations.AddDestinationLocksToEvents do
  use Ecto.Migration

  def change do
    alter table(:events, primary_key: false) do
      add :destination_locks, {:array, :binary_id}, default: []
    end

    alter table(:dead_letter_events, primary_key: false) do
      add :destination_locks, {:array, :binary_id}, default: []
    end
  end
end
