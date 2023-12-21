defmodule ER.Repo.Migrations.CreatePruners do
  use Ecto.Migration

  def change do
    create table(:pruners, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :type, :string
      add :config, :map
      add :query, :text
      add :topic_name, references(:topics, column: :name, type: :string)

      timestamps()
    end

    create index(:pruners, [:topic_name])
  end
end
