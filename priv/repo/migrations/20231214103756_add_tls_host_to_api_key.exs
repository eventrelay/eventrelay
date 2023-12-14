defmodule ER.Repo.Migrations.AddTlsHostToApiKey do
  use Ecto.Migration

  def change do
    alter table(:api_keys, primary_key: false) do
      add :tls_hostname, :string
    end
  end
end
