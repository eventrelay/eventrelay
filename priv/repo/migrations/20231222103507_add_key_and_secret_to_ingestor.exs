defmodule ER.Repo.Migrations.AddKeyAndSecretToIngestor do
  use Ecto.Migration

  def change do
    alter table(:ingestors, primary_key: false) do
      add :key, :string
      add :secret, :string
    end
  end
end
