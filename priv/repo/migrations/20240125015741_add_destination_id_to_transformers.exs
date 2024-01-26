defmodule ER.Repo.Migrations.AddDestinationIdToTransformers do
  use Ecto.Migration

  def change do
    alter table(:transformers, primary_key: false) do
      add(:destination_id, references(:destinations, type: :binary_id, on_delete: :delete_all))
    end

    drop_if_exists unique_index(:transformers, [:source_id]), mode: :cascade
  end
end
