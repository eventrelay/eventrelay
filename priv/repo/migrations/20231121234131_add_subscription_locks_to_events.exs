defmodule ER.Repo.Migrations.AddSubscriptionLocksToEvents do
  use Ecto.Migration

  def change do
    alter table(:events, primary_key: false) do
      add :subscription_locks, {:array, :binary_id}, default: []
    end

    alter table(:dead_letter_events, primary_key: false) do
      add :subscription_locks, {:array, :binary_id}, default: []
    end
  end
end
