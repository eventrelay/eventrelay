defmodule ER.Repo.Migrations.AddPrevIdToEvents do
  use Ecto.Migration

  def change do
    alter table(:events, primary_key: false) do
      add :prev_id, :binary_id
    end

    alter table(:dead_letter_events, primary_key: false) do
      add :prev_id, :binary_id
    end
  end
end
