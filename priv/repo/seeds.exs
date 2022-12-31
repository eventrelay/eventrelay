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

Faker.start()

%User{}
|> User.registration_changeset(%{email: "user@example.com", password: "password123!@"})
|> Repo.insert!()

Repo.insert!(%Topic{name: "default"})

topic = %Topic{name: "users"} |> Repo.insert!()
ER.Events.Schema.create_topic_event_table!(topic)
uuid = Faker.UUID.v4()

subscription =
  %ER.Subscriptions.Subscription{
    topic_name: "users"
  }
  |> Repo.insert!()

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
