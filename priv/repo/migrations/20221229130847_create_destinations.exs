defmodule ER.Repo.Migrations.CreateDestinations do
  use Ecto.Migration

  def change do
    create table(:destinations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :offset, :integer
      add :topic_name, references(:topics, column: :name, type: :string)
      add :topic_identifier, :string
      add :push, :boolean, default: true, null: false
      add :paused, :boolean, default: false, null: false
      add :ordered, :boolean, default: false, null: false
      add :config, :map, default: %{}
      add :destination_type, :string

      add :inserted_at, :utc_datetime, default: fragment("NOW()")
      add :updated_at, :utc_datetime, default: fragment("NOW()")
    end

    create unique_index(:destinations, [:name])
  end
end
