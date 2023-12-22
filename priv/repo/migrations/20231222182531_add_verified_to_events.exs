defmodule ER.Repo.Migrations.AddVerifiedToEvents do
  use Ecto.Migration

  def change do
    alter table(:events, primary_key: false) do
      add :verified, :boolean, default: false
    end

    alter table(:dead_letter_events, primary_key: false) do
      add :verified, :boolean, default: false
    end
  end
end
