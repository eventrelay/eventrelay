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
alias ER.Accounts.ApiKey
alias ER.Accounts

Faker.start()

%User{}
|> User.registration_changeset(%{email: "user@example.com", password: "password123!@"})
|> Repo.insert!()

Repo.insert!(%Topic{name: "default"})

topic = %Topic{name: "users"} |> Repo.insert!()
ER.Events.Event.create_table!(topic)
ER.Destinations.Delivery.create_table!(topic)

actions_topic = %Topic{name: "actions"} |> Repo.insert!()
ER.Events.Event.create_table!(actions_topic)
ER.Destinations.Delivery.create_table!(actions_topic)

webhooks_topic = %Topic{name: "webhooks"} |> Repo.insert!()
ER.Events.Event.create_table!(webhooks_topic)
ER.Destinations.Delivery.create_table!(webhooks_topic)

topics = [topic, actions_topic]

uuid = Faker.UUID.v4()

# websocket_destination =
#   %ER.Destinations.Destination{
#     name: "app1_websocket",
#     destination_type: :websocket,
#     topic_name: "users"
#   }
#   |> Repo.insert!()
#
# webhook_destination =
#   %ER.Destinations.Destination{
#     name: "app1_webhook",
#     destination_type: :webhook,
#     topic_name: "users",
#     config: %{"endpoint_url" => "http://localhost:5006/api/webhook"}
#   }
#   |> Repo.insert!()
#
# destinations = [websocket_destination, webhook_destination]

api_destination =
  %ER.Destinations.Destination{
    name: "users_api_destination",
    destination_type: :api,
    topic_name: "users"
  }
  |> Repo.insert!()

topic_destination =
  %ER.Destinations.Destination{
    name: "actions_topic_destination",
    destination_type: :topic,
    topic_name: "users",
    config: %{topic_name: "actions"}
  }
  |> Repo.insert!()

destinations = [api_destination, topic_destination]

[:admin, :producer, :consumer]
|> Enum.each(fn type ->
  attrs = %{
    name: to_string(type),
    type: type,
    status: :active,
    tls_hostname: "localhost"
  }

  {:ok, api_key} =
    Accounts.create_api_key(attrs)

  IO.puts("------------- #{inspect(type)} API Key Token -------------")

  ApiKey.encode_key_and_secret(api_key)
  |> IO.puts()

  IO.puts("------------- #{inspect(type)} API Key JWT -------------")
  ER.JWT.Token.build(api_key, %{exp: 2_999_171_638}) |> ER.unwrap_ok!() |> IO.puts()

  case type do
    :producer ->
      Enum.each(topics, fn topic ->
        ER.Accounts.create_api_key_topic(api_key, topic)
      end)

    :consumer ->
      Enum.each(destinations, fn destination ->
        ER.Accounts.create_api_key_destination(api_key, destination)
      end)

    _ ->
      nil
  end
end)

source =
  ER.Sources.create_source(%{
    "name" => "wehbook_source",
    "config" => %{},
    "type" => :webhook,
    "topic_name" => webhooks_topic.name,
    "source" => "somewhere"
  })

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
# ER.Destinations.Delivery.create_table!(topic)
# %ER.Destinations.Destination{
#   name: "dogs_webhook",
#   destination_type: "webhook",
#   push: true,
#   topic_name: "dogs",
#   config: %{"endpoint_url" => "http://localhost:5000/api/webhooks"},
#   signing_secret: ER.Auth.generate_secret()
# }
# |> Repo.insert!()
