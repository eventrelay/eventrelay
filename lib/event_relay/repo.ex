defmodule ER.Repo do
  use Ecto.Repo,
    otp_app: :event_relay,
    adapter: Ecto.Adapters.Postgres
end
