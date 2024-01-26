defmodule ER.Repo.Migrations.AddQueryToTransformers do
  use Ecto.Migration

  def change do
    alter table(:transformers, primary_key: false) do
      add :query, :text
    end
  end
end
