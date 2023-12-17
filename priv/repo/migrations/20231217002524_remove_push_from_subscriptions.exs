defmodule ER.Repo.Migrations.RemovePushFromSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:subscriptions, primary_key: false) do
      remove :push
    end
  end
end
