defmodule ER.Repo.Migrations.AddStatusToDeliveries do
  use Ecto.Migration

  def change do
    alter table(:deliveries, primary_key: false) do
      add(:status, :string, null: false)
      remove(:success)
    end
  end
end
