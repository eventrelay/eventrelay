defmodule ER.Repo.Migrations.AddTypeToTransformers do
  use Ecto.Migration

  def change do
    alter table(:transformers, primary_key: false) do
      add :type, :string
    end
  end
end
