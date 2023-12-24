defmodule ER.Destinations.ServerTest do
  use ER.DataCase
  import ER.Factory
  alias ER.Destinations.Server

  describe "handle_event?/2" do
    setup do
      destination = insert(:destination, query: "data.first_name == 'Bill'")
      event = insert(:event, name: "user.created", data: %{"first_name" => "Bill"})
      {:ok, destination: destination, event: event}
    end

    test "returns true if the destination query matches the event name", %{
      destination: destination,
      event: event
    } do
      destination = %{destination | query: "name == 'user.created'"}
      assert Server.handle_event?(destination, event)
    end

    test "returns false if the destination query does not matches the event name", %{
      destination: destination,
      event: event
    } do
      destination = %{destination | query: "name == 'user.updated'"}
      refute Server.handle_event?(destination, event)
    end
  end
end
