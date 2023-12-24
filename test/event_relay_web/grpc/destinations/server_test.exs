defmodule ERWeb.Grpc.EventRelay.Destinations.ServerTest do
  use ER.DataCase

  alias ERWeb.Grpc.EventRelay.Destinations.Server
  alias ER.Events
  import ER.Factory

  alias ERWeb.Grpc.Eventrelay.{
    CreateDestinationRequest,
    NewDestination,
    DeleteDestinationRequest,
    ListDestinationsRequest
  }

  setup do
    {:ok, topic} = Events.create_topic(%{name: "log"})

    {:ok, topic: topic}
  end

  describe "create_destination/2" do
    test "create a new destination", %{topic: topic} do
      request = %CreateDestinationRequest{
        destination: %NewDestination{
          name: "Test Destination",
          topic_name: topic.name,
          config: %{"endpoint_url" => "http://localhost:9000"},
          destination_type: "webhook"
        }
      }

      result = Server.create_destination(request, nil)

      refute ER.Destinations.get_destination(result.destination.id) == nil
    end
  end

  describe "delete_destination/2" do
    test "deletes a destination", %{topic: topic} do
      destination = insert(:destination, topic: topic)

      request = %DeleteDestinationRequest{
        id: destination.id
      }

      result = Server.delete_destination(request, nil)

      assert ER.Destinations.get_destination(result.destination.id) == nil
    end
  end

  describe "list_destinations/2" do
    test "list destinations", %{topic: topic} do
      insert(:destination, topic: topic)
      insert(:destination, topic: topic)

      request = %ListDestinationsRequest{}

      result = Server.list_destinations(request, nil)
      assert result.total_count == 2
    end
  end
end
