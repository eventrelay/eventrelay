# Mocks
Mox.defmock(ER.Events.ChannelCacheBehaviorMock, for: ER.Events.ChannelCacheBehavior)
Application.put_env(:event_relay, :channel_cache, ER.Events.ChannelCacheBehaviorMock)

ExUnit.start()
Faker.start()
{:ok, _} = Application.ensure_all_started(:ex_machina)
Ecto.Adapters.SQL.Sandbox.mode(ER.Repo, :manual)
