defmodule ER.Subscriptions.SubscriptionTest do
  use ER.DataCase
  alias ER.Subscriptions.Subscription
  import ER.Factory

  describe "matches?/2" do
    setup do
      subscription = insert(:subscription, query: "data.first_name == 'Bill'")
      event = insert(:event, name: "user.created", data: %{"first_name" => "Bill"})
      {:ok, subscription: subscription, event: event}
    end

    test "returns true if there is no query for the subscription" do
      event = insert(:event)
      subscription = insert(:subscription)
      assert Subscription.matches?(subscription, event)
    end

    test "returns true if the subscription query matches the event data", %{
      subscription: subscription,
      event: event
    } do
      assert Subscription.matches?(subscription, event)
    end

    test "returns true if the subscription query matches the event name", %{
      subscription: subscription,
      event: event
    } do
      subscription = %{subscription | query: "name == 'user.created'"}
      assert Subscription.matches?(subscription, event)
    end

    test "returns false if the subscription query does not matches the event name", %{
      subscription: subscription,
      event: event
    } do
      subscription = %{subscription | query: "name == 'user.updated'"}
      refute Subscription.matches?(subscription, event)
    end
  end
end
