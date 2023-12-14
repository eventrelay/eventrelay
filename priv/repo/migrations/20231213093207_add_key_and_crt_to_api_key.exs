defmodule ER.Repo.Migrations.AddKeyAndCrtToApiKey do
  use Ecto.Migration

  def change do
    alter table(:api_keys, primary_key: false) do
      add :tls_key, :text
      add :tls_crt, :text
    end
  end
end
