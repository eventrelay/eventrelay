defmodule ER.Repo.Migrations.CreateDeliveries do
  use Ecto.Migration

  def change do
    create table(:deliveries, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:attempts, {:array, :map})
      add(:success, :boolean, default: false, null: false)
      add(:event_id, :binary_id)

      add(:subscription_id, references(:subscriptions, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      add(:inserted_at, :utc_datetime, default: fragment("NOW()"))
      add(:updated_at, :utc_datetime, default: fragment("NOW()"))
    end

    create(unique_index(:deliveries, [:event_id, :subscription_id]))
  end
end
