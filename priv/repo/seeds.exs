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

events =
  Enum.map(1..1000, fn _ ->
    %{
      name: Faker.Name.name(),
      topic_identifier: "default",
      occurred_at: DateTime.utc_now() |> DateTime.truncate(:second),
      source: "grpc",
      data: %{name: "testing"},
      context: %{ip_address: "127.0.0.1"}
    }
  end)

Repo.insert_all(Event, events)
