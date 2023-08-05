defmodule ER.SubscriptionsTest do
  use ER.DataCase

  alias ER.Subscriptions

  import ER.Test.Setups
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
        topic_name: topic.name,
        subscription_type: "webhook"
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
             |> Repo.preload(subscription: [:topic]) == delivery
    end

    test "create_delivery/1 with valid data creates a delivery" do
      subscription = insert(:subscription)
      event = insert(:event)

      valid_attrs = %{
        attempts: [],
        event_id: event.id,
        subscription_id: subscription.id,
        status: :success
      }

      assert {:ok, %Delivery{} = delivery} = Subscriptions.create_delivery(valid_attrs)
      assert delivery.attempts == []
    end

    test "create_delivery/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Subscriptions.create_delivery(@invalid_attrs)
    end

    test "create_delivery_for_topic/2 with invalid data creates a event in the dead letter events table" do
      subscription = insert(:subscription)
      topic_name = subscription.topic_name

      attrs = %{
        subscription_id: subscription.id,
        status: :success
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Subscriptions.create_delivery_for_topic(topic_name, attrs)

      assert [event_id: {"can't be blank", [validation: :required]}] = changeset.errors
    end

    test "create_delivery_for_topic/2 with no data creates a event in the dead letter events table" do
      topic = insert(:topic)
      subscription = insert(:subscription, topic: topic)
      event = insert(:event, topic: topic)
      ER.Subscriptions.Delivery.create_table!(topic)

      attrs = %{
        event_id: event.id,
        subscription_id: subscription.id,
        status: :success
      }

      assert {:ok, %Delivery{} = delivery} =
               Subscriptions.create_delivery_for_topic(topic.name, attrs)

      assert Ecto.get_meta(delivery, :source) ==
               "#{topic.name}_deliveries"

      ER.Subscriptions.Delivery.drop_table!(topic)
    end

    test "create_delivery_for_topic/2 when the topic delivery table does not exist it returns an error tuple" do
      topic = insert(:topic)
      subscription = insert(:subscription, topic: topic)
      event = insert(:event, topic: topic)

      attrs = %{
        event_id: event.id,
        subscription_id: subscription.id,
        status: :success
      }

      assert {:error, reason} = Subscriptions.create_delivery_for_topic(topic.name, attrs)

      assert reason ==
               "relation \"#{topic.name}_deliveries\" does not exist"
    end

    test "update_delivery/2 with valid data updates the delivery" do
      event = insert(:event)
      delivery = insert(:delivery, event_id: event.id)
      update_attrs = %{attempts: []}

      assert {:ok, %Delivery{} = delivery} = Subscriptions.update_delivery(delivery, update_attrs)
      assert delivery.attempts == []
    end

    test "update_delivery/2 with invalid data returns error changeset" do
      delivery = insert(:delivery)
      assert {:error, %Ecto.Changeset{}} = Subscriptions.update_delivery(delivery, @invalid_attrs)

      assert delivery ==
               Subscriptions.get_delivery!(delivery.id)
               |> Repo.preload(subscription: [:topic])
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

  describe "list_deliveries_for_subscription/2" do
    setup [:setup_topic, :setup_deliveries]

    test "list_deliveries_for_subscription/2 returns all pending deliveries for a subscription",
         %{
           topic: topic,
           subscription: subscription,
           pending_delivery: pending_delivery,
           pending_delivery_2: pending_delivery_2,
           successful_delivery: successful_delivery
         } do
      pending_delivery_ids =
        Enum.map(
          Subscriptions.list_deliveries_for_subscription(
            topic.name,
            subscription.id,
            status: :pending
          ),
          & &1.id
        )

      assert pending_delivery_ids == [pending_delivery.id, pending_delivery_2.id]
      refute successful_delivery.id in pending_delivery_ids
    end
  end

  describe "update_all_deliveries/2" do
    setup [:setup_topic, :setup_deliveries]

    test "updates status of deliveries",
         %{
           topic: topic,
           subscription: subscription,
           pending_delivery: pending_delivery,
           pending_delivery_2: pending_delivery_2
         } do
      deliveries =
        Subscriptions.list_deliveries_for_subscription(
          topic.name,
          subscription.id,
          status: :pending
        )

      Subscriptions.update_all_deliveries(topic.name, deliveries, set: [status: "success"])

      deliveries =
        Subscriptions.list_deliveries_for_subscription(
          topic.name,
          subscription.id,
          status: :success
        )

      successful_delivery_ids = Enum.map(deliveries, & &1.id)

      assert pending_delivery.id in successful_delivery_ids
      assert pending_delivery_2.id in successful_delivery_ids

      assert Enum.all?(deliveries, &(&1.status == :success))
    end
  end
end
