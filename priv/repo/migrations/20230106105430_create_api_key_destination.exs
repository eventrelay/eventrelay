defmodule ER.Repo.Migrations.CreateApiKeyDestination do
  use Ecto.Migration

  def change do
    create table(:api_key_destinations, primary_key: false) do
      add(:api_key_id, references(:api_keys, on_delete: :delete_all, type: :binary_id))

      add(:destination_id, references(:destinations, on_delete: :delete_all, type: :binary_id))

      add(:inserted_at, :utc_datetime, default: fragment("NOW()"))
      add(:updated_at, :utc_datetime, default: fragment("NOW()"))
    end

    create(unique_index(:api_key_destinations, [:api_key_id, :destination_id]))

    create table(:api_key_topics, primary_key: false) do
      add(:api_key_id, references(:api_keys, on_delete: :delete_all, type: :binary_id),
        primary_key: true
      )

      add(:topic_name, references(:topics, column: :name, on_delete: :delete_all, type: :string),
        primary_key: true
      )

      add(:inserted_at, :utc_datetime, default: fragment("NOW()"))
      add(:updated_at, :utc_datetime, default: fragment("NOW()"))
    end

    create(unique_index(:api_key_topics, [:api_key_id, :topic_name]))
  end
end
