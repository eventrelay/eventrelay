defmodule ER.Subscriptions.ServerTest do
  use ER.DataCase
  import ER.Factory
  alias ER.Subscriptions.Server

  describe "handle_event?/2" do
    setup do
      subscription = insert(:subscription, query: "data.first_name == 'Bill'")
      event = insert(:event, name: "user.created", data: %{"first_name" => "Bill"})
      {:ok, subscription: subscription, event: event}
    end

    test "returns true if the subscription query matches the event name", %{
      subscription: subscription,
      event: event
    } do
      subscription = %{subscription | query: "name == 'user.created'"}
      assert Server.handle_event?(subscription, event)
    end

    test "returns false if the subscription query does not matches the event name", %{
      subscription: subscription,
      event: event
    } do
      subscription = %{subscription | query: "name == 'user.updated'"}
      refute Server.handle_event?(subscription, event)
    end
  end
end
