defmodule ER.Repo.Migrations.AddIngestorIdToTransformers do
  use Ecto.Migration

  def change do
    alter table(:transformers, primary_key: false) do
      add(:ingestor_id, references(:ingestors, type: :binary_id, on_delete: :delete_all))
    end

    create(unique_index(:transformers, [:ingestor_id]))
  end
end
