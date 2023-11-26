defmodule ER.Repo.Migrations.AddSigningSecretToSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:subscriptions, primary_key: false) do
      add :signing_secret, :string
    end
  end
end
