defmodule ER.Repo.Migrations.CreateMetrics do
  use Ecto.Migration

  def change do
    create table(:metrics, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :field_path, :string
      add :type, :string
      add :filters, :map
      add :topic_name, references(:topics, column: :name, type: :string)
      add :topic_identifier, :string

      timestamps()
    end
  end
end
