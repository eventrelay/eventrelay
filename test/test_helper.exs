# Mocks
Mimic.copy(ERWeb.Endpoint)
Mimic.copy(ER.Events.ChannelCache)
Mimic.copy(Req)
Mimic.copy(ERWeb.RateLimiter)

ExUnit.start()
Faker.start()
{:ok, _} = Application.ensure_all_started(:ex_machina)
Ecto.Adapters.SQL.Sandbox.mode(ER.Repo, :manual)
