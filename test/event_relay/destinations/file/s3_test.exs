defmodule ER.Destinations.File.S3Test do
  use ER.DataCase
  import ER.Factory
  import ER.Test.Helpers
  alias ER.Events
  use Mimic

  describe "put/3" do
    setup do
      {:ok, topic} = ER.Events.create_topic(%{name: "users"})

      destination =
        insert(:destination,
          topic: topic,
          config: %{
            "region" => "us-east-2",
            "bucket" => "eventrelay_dev",
            "access_key_id" => "abc123",
            "secret_access_key" => "secret123",
            "format" => "jsonl"
          }
        )

      {:ok, event} =
        params_for(:event,
          topic: topic,
          name: "user.updated",
          group_key: "target_group",
          source: "app",
          offset: 1,
          data: %{"first_name" => "Thomas"}
        )
        |> Events.create_event_for_topic()

      {:ok, topic: topic, event: event, destination: destination}
    end

    test "puts an object in S3", %{
      event: event,
      destination: destination
    } do
      ExAws
      |> expect(:request!, fn %ExAws.Operation.S3{} = _request, opts ->
        assert opts == [
                 region: "us-east-2",
                 access_key_id: "abc123",
                 secret_access_key: "secret123"
               ]
      end)

      ER.Destinations.File.put(
        %ER.Destinations.File.S3{destination: destination},
        [build_broadway_message(event)],
        []
      )
    end
  end
end
