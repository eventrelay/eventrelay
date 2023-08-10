defmodule ER.Repo.Migrations.AddReturnTypeToTransformers do
  use Ecto.Migration

  def change do
    alter table(:transformers, primary_key: false) do
      add :return_type, :string
    end
  end
end
