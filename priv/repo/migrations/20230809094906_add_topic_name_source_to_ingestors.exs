defmodule ER.Repo.Migrations.AddTopicNameSourceToIngestors do
  use Ecto.Migration

  def change do
    alter table(:ingestors, primary_key: false) do
      add :topic_name, references(:topics, column: :name, type: :string)
      add :source, :string
    end
  end
end
