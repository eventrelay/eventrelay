defmodule ER.Repo.Migrations.CreateApiKey do
  use Ecto.Migration

  def change do
    create table(:api_keys, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:key, :string, null: false)
      add(:secret, :string, null: false)
      add(:status, :string, null: false)
      add(:type, :string, null: false)

      add(:inserted_at, :utc_datetime, default: fragment("NOW()"))
      add(:updated_at, :utc_datetime, default: fragment("NOW()"))
    end

    create(
      unique_index(:api_keys, [:key, :secret, :status, :type],
        name: :api_keys_key_secret_status_type_index
      )
    )
  end
end
