# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ER.Repo.insert!(%ER.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
#
alias ER.Repo

alias ER.Accounts.User
alias ER.Events.Topic
alias ER.Events.Event
alias ER.Accounts.ApiKey
alias ER.Accounts

Faker.start()

%User{}
|> User.registration_changeset(%{email: "user@example.com", password: "password123!@"})
|> Repo.insert!()

Repo.insert!(%Topic{name: "default"})

topic = %Topic{name: "users"} |> Repo.insert!()
ER.Events.Event.create_table!(topic)
ER.Subscriptions.Delivery.create_table!(topic)
uuid = Faker.UUID.v4()

websocket_subscription =
  %ER.Subscriptions.Subscription{
    name: "app1_websocket",
    subscription_type: "websocket",
    push: true,
    topic_name: "users"
  }
  |> Repo.insert!()

webhook_subscription =
  %ER.Subscriptions.Subscription{
    name: "app1_webhook",
    subscription_type: "webhook",
    push: true,
    topic_name: "users",
    config: %{"endpoint_url" => "http://localhost:5006/api/webhook"}
  }
  |> Repo.insert!()

subscriptions = [websocket_subscription, webhook_subscription]

[:admin, :producer, :consumer]
|> Enum.each(fn type ->
  api_key = ApiKey.build(type, :active)
  api_key = %{api_key | name: to_string(type)}
  Accounts.create_api_key(api_key)
  IO.puts("------------- #{inspect(type)} API Key Token -------------")

  ApiKey.encode_key_and_secret(api_key)
  |> IO.puts()

  IO.puts("------------- #{inspect(type)} API Key JWT -------------")
  ER.JWT.Token.build(api_key, %{exp: 2_999_171_638}) |> ER.unwrap_ok!() |> IO.puts()

  case type do
    :producer ->
      ER.Accounts.create_api_key_topic(api_key, topic)

    :consumer ->
      Enum.each(subscriptions, fn subscription ->
        ER.Accounts.create_api_key_subscription(api_key, subscription)
      end)

    _ ->
      nil
  end
end)

# events =
#   Enum.map(1..1000, fn _ ->
#     %{
#       name: "user.created",
#       topic_name: topic.name,
#       topic_identifier: uuid,
#       occurred_at: DateTime.utc_now() |> DateTime.truncate(:second),
#       source: "grpc",
#       data: %{first_name: Faker.Name.first_name(), last_name: Faker.Name.last_name()},
#       context: %{ip_address: "127.0.0.1"}
#     }
#   end)

# Repo.insert_all(Event, events)

# topic = %Topic{name: "dogs"} |> Repo.insert!()
#
# ER.Events.Event.create_table!(topic)
# ER.Subscriptions.Delivery.create_table!(topic)
# %ER.Subscriptions.Subscription{
#   name: "dogs_webhook",
#   subscription_type: "webhook",
#   push: true,
#   topic_name: "dogs",
#   config: %{"endpoint_url" => "http://localhost:5000/api/webhooks"},
#   signing_secret: ER.Auth.generate_secret()
# }
# |> Repo.insert!()
