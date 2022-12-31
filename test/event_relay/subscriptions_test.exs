defmodule ER.SubscriptionsTest do
  use ER.DataCase

  alias ER.Subscriptions

  import ER.Factory

  describe "subscriptions" do
    alias ER.Subscriptions.Subscription

    @invalid_attrs %{name: nil, offset: nil, ordered: nil, pull: nil, topic_name: nil}

    test "list_subscriptions/0 returns all subscriptions" do
      subscription = insert(:subscription)
      assert Enum.map(Subscriptions.list_subscriptions(), & &1.id) == [subscription.id]
    end

    test "get_subscription!/1 returns the subscription with given id" do
      subscription = insert(:subscription)

      assert Subscriptions.get_subscription!(subscription.id) |> Repo.preload(:topic) ==
               subscription
    end

    test "create_subscription/1 with valid data creates a subscription" do
      topic = insert(:topic)

      valid_attrs = %{
        name: "some name",
        offset: 42,
        ordered: true,
        pull: true,
        topic_name: topic.name
      }

      assert {:ok, %Subscription{} = subscription} =
               Subscriptions.create_subscription(valid_attrs)

      assert subscription.name == "some_name"
      assert subscription.offset == 42
      assert subscription.ordered == true
      assert subscription.push == true
      assert subscription.paused == false
      assert subscription.topic_name == topic.name
    end

    test "create_subscription/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Subscriptions.create_subscription(@invalid_attrs)
    end

    test "update_subscription/2 with valid data updates the subscription" do
      subscription = insert(:subscription)
      topic = insert(:topic)

      update_attrs = %{
        name: "some updated name",
        offset: 43,
        ordered: false,
        topic_name: topic.name
      }

      assert {:ok, %Subscription{} = subscription} =
               Subscriptions.update_subscription(subscription, update_attrs)

      assert subscription.name == "some_updated_name"
      assert subscription.offset == 43
      assert subscription.ordered == false
      assert subscription.push == true
      assert subscription.topic_name == topic.name
    end

    test "update_subscription/2 with invalid data returns error changeset" do
      subscription = insert(:subscription)

      assert {:error, %Ecto.Changeset{}} =
               Subscriptions.update_subscription(subscription, @invalid_attrs)

      assert subscription ==
               Subscriptions.get_subscription!(subscription.id) |> Repo.preload(:topic)
    end

    test "delete_subscription/1 deletes the subscription" do
      subscription = insert(:subscription)
      assert {:ok, %Subscription{}} = Subscriptions.delete_subscription(subscription)
      assert_raise Ecto.NoResultsError, fn -> Subscriptions.get_subscription!(subscription.id) end
    end

    test "change_subscription/1 returns a subscription changeset" do
      subscription = insert(:subscription)
      assert %Ecto.Changeset{} = Subscriptions.change_subscription(subscription)
    end
  end

  describe "deliveries" do
    alias ER.Subscriptions.Delivery

    @invalid_attrs %{attempts: nil}

    test "list_deliveries/0 returns all deliveries" do
      delivery = insert(:delivery)
      assert Enum.map(Subscriptions.list_deliveries(), & &1.id) == [delivery.id]
    end

    test "get_delivery!/1 returns the delivery with given id" do
      delivery = insert(:delivery)

      assert Subscriptions.get_delivery!(delivery.id)
             |> Repo.preload([:event, subscription: [:topic]]) == delivery
    end

    test "create_delivery/1 with valid data creates a delivery" do
      subscription = insert(:subscription)
      event = insert(:event)
      valid_attrs = %{attempts: [], event_id: event.id, subscription_id: subscription.id}

      assert {:ok, %Delivery{} = delivery} = Subscriptions.create_delivery(valid_attrs)
      assert delivery.attempts == []
    end

    test "create_delivery/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Subscriptions.create_delivery(@invalid_attrs)
    end

    test "update_delivery/2 with valid data updates the delivery" do
      delivery = insert(:delivery)
      update_attrs = %{attempts: []}

      assert {:ok, %Delivery{} = delivery} = Subscriptions.update_delivery(delivery, update_attrs)
      assert delivery.attempts == []
    end

    test "update_delivery/2 with invalid data returns error changeset" do
      delivery = insert(:delivery)
      assert {:error, %Ecto.Changeset{}} = Subscriptions.update_delivery(delivery, @invalid_attrs)

      assert delivery ==
               Subscriptions.get_delivery!(delivery.id)
               |> Repo.preload([:event, subscription: [:topic]])
    end

    test "delete_delivery/1 deletes the delivery" do
      delivery = insert(:delivery)
      assert {:ok, %Delivery{}} = Subscriptions.delete_delivery(delivery)
      assert_raise Ecto.NoResultsError, fn -> Subscriptions.get_delivery!(delivery.id) end
    end

    test "change_delivery/1 returns a delivery changeset" do
      delivery = insert(:delivery)
      assert %Ecto.Changeset{} = Subscriptions.change_delivery(delivery)
    end
  end
end
