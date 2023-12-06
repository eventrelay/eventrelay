defmodule ER.Repo.Migrations.AddQueryToSubscription do
  use Ecto.Migration

  def change do
    alter table(:subscriptions, primary_key: false) do
      add :query, :text
    end
  end
end
