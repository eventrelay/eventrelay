defmodule ER.Repo.Migrations.AddSigningSecretToDestinations do
  use Ecto.Migration

  def change do
    alter table(:destinations, primary_key: false) do
      add :signing_secret, :string
    end
  end
end
