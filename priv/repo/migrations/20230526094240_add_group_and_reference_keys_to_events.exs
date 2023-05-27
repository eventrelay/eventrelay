defmodule ER.Repo.Migrations.AddGroupAndReferenceKeysToEvents do
  use Ecto.Migration

  def change do
    alter table(:events, primary_key: false) do
      add(:group_key, :string)
      add(:reference_key, :string)
      add(:trace_key, :string)
    end
  end
end
