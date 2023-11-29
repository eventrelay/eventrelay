defmodule ER.Repo.Migrations.AddNameToApiKeys do
  use Ecto.Migration

  def change do
    alter table(:api_keys, primary_key: false) do
      add :name, :string
    end
  end
end
