defmodule ER.Destinations.Database.Postgres.ServerTest do
  use ER.DataCase
  import ER.Test.Setups
  import ER.Factory

  defp setup_destination(context) do
    destination =
      insert(:destination,
        topic: context.topic,
        config: %{
          "table_name" => "events",
          "hostname" => "127.0.0.1",
          "database" => "event_relay_other",
          "username" => "postgres",
          "password" => "postgres",
          "port" => 5432
        }
      )

    {:ok, destination: destination}
  end

  describe "insert/2" do
    setup [:setup_topic, :setup_messages, :setup_destination]

    @tag :integration
    test "inserts records", %{destination: destination, messages: messages} do
      # This test requires a separate database setup called event_relay_other. See
      # the destination config above.
      ER.Destinations.Database.Postgres.Server.factory(destination.id)
      {:ok, result} = ER.Destinations.Database.Postgres.Server.insert(destination.id, messages)
      assert result.num_rows == 2
      assert result.command == :insert
      ER.Destinations.Database.Postgres.Server.reset(destination.id)
      ER.Destinations.Database.Postgres.Server.stop(destination.id)
    end
  end
end
