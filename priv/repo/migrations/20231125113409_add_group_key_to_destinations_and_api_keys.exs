defmodule ER.Repo.Migrations.AddGroupKeyToDestinationsAndApiKeys do
  use Ecto.Migration

  def change do
    alter table(:destinations, primary_key: false) do
      add :group_key, :string
    end

    alter table(:api_keys, primary_key: false) do
      add :group_key, :string
    end

    alter table(:topics, primary_key: false) do
      add :group_key, :string
    end
  end
end
