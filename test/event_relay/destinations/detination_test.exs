defmodule ER.Destinations.DestinationTest do
  use ER.DataCase
  alias ER.Destinations.Destination
  import ER.Factory

  describe "matches?/2" do
    setup do
      destination = insert(:destination, query: "data.first_name == 'Bill'")
      event = insert(:event, name: "user.created", data: %{"first_name" => "Bill"})
      {:ok, destination: destination, event: event}
    end

    test "returns true if there is no query for the destination" do
      event = insert(:event)
      destination = insert(:destination)
      assert Destination.matches?(destination, event)
    end

    test "returns true if the destination query matches the event data", %{
      destination: destination,
      event: event
    } do
      assert Destination.matches?(destination, event)
    end

    test "returns true if the destination query matches the event name", %{
      destination: destination,
      event: event
    } do
      destination = %{destination | query: "name == 'user.created'"}
      assert Destination.matches?(destination, event)
    end

    test "returns false if the destination query does not matches the event name", %{
      destination: destination,
      event: event
    } do
      destination = %{destination | query: "name == 'user.updated'"}
      refute Destination.matches?(destination, event)
    end
  end
end
