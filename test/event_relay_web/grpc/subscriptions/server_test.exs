defmodule ERWeb.Grpc.EventRelay.Subscriptions.ServerTest do
  use ER.DataCase

  alias ERWeb.Grpc.EventRelay.Subscriptions.Server
  alias ER.Events
  import ER.Factory

  alias ERWeb.Grpc.Eventrelay.{
    CreateSubscriptionRequest,
    NewSubscription,
    DeleteSubscriptionRequest,
    ListSubscriptionsRequest
  }

  setup do
    {:ok, topic} = Events.create_topic(%{name: "log"})

    {:ok, topic: topic}
  end

  describe "create_subscription/2" do
    test "create a new subscription", %{topic: topic} do
      request = %CreateSubscriptionRequest{
        subscription: %NewSubscription{
          name: "Test Subscription",
          topic_name: topic.name,
          config: %{"endpoint_url" => "http://localhost:9000"},
          subscription_type: "webhook"
        }
      }

      result = Server.create_subscription(request, nil)

      refute ER.Subscriptions.get_subscription(result.subscription.id) == nil
    end
  end

  describe "delete_subscription/2" do
    test "deletes a subscription", %{topic: topic} do
      subscription = insert(:subscription, topic: topic)

      request = %DeleteSubscriptionRequest{
        id: subscription.id
      }

      result = Server.delete_subscription(request, nil)

      assert ER.Subscriptions.get_subscription(result.subscription.id) == nil
    end
  end

  describe "list_subscriptions/2" do
    test "list subscriptions", %{topic: topic} do
      insert(:subscription, topic: topic)
      insert(:subscription, topic: topic)

      request = %ListSubscriptionsRequest{}

      result = Server.list_subscriptions(request, nil)
      assert result.total_count == 2
    end
  end
end
