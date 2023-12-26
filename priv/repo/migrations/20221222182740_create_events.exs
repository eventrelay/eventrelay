defmodule ER.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :topic_name, references(:topics, column: :name, type: :string)
      add :topic_identifier, :string
      add :user_key, :string
      add :anonymous_key, :string
      add :offset, :serial
      add :source, :string
      add :occurred_at, :utc_datetime
      add :context, :map
      add :data, :map
      add :errors, {:array, :string}

      add :inserted_at, :utc_datetime, default: fragment("NOW()")
      add :updated_at, :utc_datetime, default: fragment("NOW()")
    end

    create table(:dead_letter_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :topic_name, :string
      add :topic_identifier, :string
      add :user_key, :string
      add :anonymous_key, :string
      add :offset, :serial
      add :source, :string
      add :occurred_at, :utc_datetime
      add :context, :map
      add :data, :map
      add :errors, {:array, :string}

      add :inserted_at, :utc_datetime, default: fragment("NOW()")
      add :updated_at, :utc_datetime, default: fragment("NOW()")
    end
  end
end
