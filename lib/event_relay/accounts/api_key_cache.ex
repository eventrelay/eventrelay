defmodule ER.Accounts.ApiKeyCache do
  use Nebulex.Cache,
    otp_app: :event_relay,
    adapter: Nebulex.Adapters.Local
end
