defmodule ER.Repo.Migrations.AddSourceIdToTransformers do
  use Ecto.Migration

  def change do
    alter table(:transformers, primary_key: false) do
      add(:source_id, references(:sources, type: :binary_id, on_delete: :delete_all))
    end

    create(unique_index(:transformers, [:source_id]))
  end
end
