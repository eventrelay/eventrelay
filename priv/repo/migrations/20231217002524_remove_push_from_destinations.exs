defmodule ER.Repo.Migrations.RemovePushFromDestinations do
  use Ecto.Migration

  def change do
    alter table(:destinations, primary_key: false) do
      remove :push
    end
  end
end
