defmodule ER.Repo.Migrations.AddKeyAndSecretToSource do
  use Ecto.Migration

  def change do
    alter table(:sources, primary_key: false) do
      add :key, :string
      add :secret, :string
    end
  end
end
