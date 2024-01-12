defmodule ER.DestinationsTest do
  use ER.DataCase

  alias ER.Destinations
  alias ER.Events

  import ER.Test.Setups
  import ER.Factory

  describe "destinations" do
    alias ER.Destinations.Destination

    @invalid_attrs %{name: nil, offset: nil, ordered: nil, pull: nil, topic_name: nil}

    test "list_destinations/0 returns all destinations" do
      destination = insert(:destination)
      assert Enum.map(Destinations.list_destinations(), & &1.id) == [destination.id]
    end

    test "get_destination!/1 returns the destination with given id" do
      destination = insert(:destination)

      assert Destinations.get_destination!(destination.id) |> Repo.preload(:topic) ==
               destination
    end

    test "create_destination/1 with valid data creates a destination" do
      topic = insert(:topic)

      valid_attrs = %{
        name: "some name",
        offset: 42,
        ordered: true,
        pull: true,
        topic_name: topic.name,
        destination_type: "webhook"
      }

      assert {:ok, %Destination{} = destination} =
               Destinations.create_destination(valid_attrs)

      assert destination.name == "some_name"
      assert destination.offset == 42
      assert destination.ordered == true
      assert destination.paused == false
      assert destination.topic_name == topic.name
      refute destination.signing_secret == nil
    end

    test "create_destination/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Destinations.create_destination(@invalid_attrs)
    end

    test "update_destination/2 with valid data updates the destination" do
      destination = insert(:destination)
      original_signing_secret = destination.signing_secret
      topic = insert(:topic)

      update_attrs = %{
        name: "some updated name",
        offset: 43,
        ordered: false,
        topic_name: topic.name
      }

      assert {:ok, %Destination{} = destination} =
               Destinations.update_destination(destination, update_attrs)

      assert destination.name == "some_updated_name"
      assert destination.offset == 43
      assert destination.ordered == false
      assert destination.topic_name == topic.name
      assert destination.signing_secret == original_signing_secret
    end

    test "update_destination/2 with invalid data returns error changeset" do
      destination = insert(:destination)

      assert {:error, %Ecto.Changeset{}} =
               Destinations.update_destination(destination, @invalid_attrs)

      assert destination ==
               Destinations.get_destination!(destination.id) |> Repo.preload(:topic)
    end

    test "delete_destination/1 deletes the destination" do
      destination = insert(:destination)
      assert {:ok, %Destination{}} = Destinations.delete_destination(destination)
      assert_raise Ecto.NoResultsError, fn -> Destinations.get_destination!(destination.id) end
    end

    test "change_destination/1 returns a destination changeset" do
      destination = insert(:destination)
      assert %Ecto.Changeset{} = Destinations.change_destination(destination)
    end
  end

  describe "deliveries" do
    alias ER.Destinations.Delivery

    @invalid_attrs %{attempts: nil}

    test "list_deliveries/0 returns all deliveries" do
      delivery = insert(:delivery)
      assert Enum.map(Destinations.list_deliveries(), & &1.id) == [delivery.id]
    end

    test "get_delivery!/1 returns the delivery with given id" do
      delivery = insert(:delivery)

      assert Destinations.get_delivery!(delivery.id)
             |> Repo.preload(destination: [:topic]) == delivery
    end

    test "create_delivery/1 with valid data creates a delivery" do
      destination = insert(:destination)
      event = insert(:event)

      valid_attrs = %{
        attempts: [],
        event_id: event.id,
        destination_id: destination.id,
        status: :success
      }

      assert {:ok, %Delivery{} = delivery} = Destinations.create_delivery(valid_attrs)
      assert delivery.attempts == []
    end

    test "create_delivery/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Destinations.create_delivery(@invalid_attrs)
    end

    test "get_delivery_for_topic_by_event_id/2 returns a delivery if one exists for that event id" do
      {:ok, topic} = Events.create_topic(%{name: "users"})

      attrs =
        params_for(:event,
          topic: topic
        )

      {:ok, event} = Events.create_event_for_topic(attrs)

      destination = insert(:destination, topic: topic)
      topic_name = destination.topic_name

      attrs = %{
        event_id: event.id,
        destination_id: destination.id,
        status: :success
      }

      Destinations.create_delivery_for_topic(topic_name, attrs)

      refute Destinations.get_delivery_for_topic_by_event_id(event.id, topic_name: topic_name) ==
               nil
    end

    test "get_delivery_for_topic_by_event_id/2 returns nil if one does not exists for that event id" do
      {:ok, topic} = Events.create_topic(%{name: "users"})

      attrs =
        params_for(:event,
          topic: topic
        )

      {:ok, event} = Events.create_event_for_topic(attrs)

      destination = insert(:destination, topic: topic)
      topic_name = destination.topic_name

      assert Destinations.get_delivery_for_topic_by_event_id(event.id, topic_name: topic_name) ==
               nil
    end

    test "get_or_create_delivery_for_topic_by_event_id/2 returns a delivery if one exists for that event id" do
      {:ok, topic} = Events.create_topic(%{name: "users"})

      attrs =
        params_for(:event,
          topic: topic
        )

      {:ok, event} = Events.create_event_for_topic(attrs)

      destination = insert(:destination, topic: topic)
      topic_name = destination.topic_name

      attrs = %{
        event_id: event.id,
        destination_id: destination.id,
        status: :pending
      }

      {:ok, existing_delivery} = Destinations.create_delivery_for_topic(topic_name, attrs)

      {:ok, delivery} =
        Destinations.get_or_create_delivery_for_topic_by_event_id(topic_name, attrs)

      assert delivery.id == existing_delivery.id
    end

    test "get_or_create_delivery_for_topic_by_event_id/2 returns a delivery if one does not exists for that event id" do
      {:ok, topic} = Events.create_topic(%{name: "users"})

      attrs =
        params_for(:event,
          topic: topic
        )

      {:ok, event} = Events.create_event_for_topic(attrs)

      destination = insert(:destination, topic: topic)
      topic_name = destination.topic_name

      attrs = %{
        event_id: event.id,
        destination_id: destination.id,
        status: :pending
      }

      assert Destinations.get_delivery_for_topic_by_event_id(event.id, topic_name: topic_name) ==
               nil

      {:ok, delivery} =
        Destinations.get_or_create_delivery_for_topic_by_event_id(topic_name, attrs)

      refute delivery == nil
    end

    test "create_delivery_for_topic/2 with invalid data creates a event in the dead letter events table" do
      destination = insert(:destination)
      topic_name = destination.topic_name

      attrs = %{
        destination_id: destination.id,
        status: :success
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Destinations.create_delivery_for_topic(topic_name, attrs)

      assert [event_id: {"can't be blank", [validation: :required]}] = changeset.errors
    end

    test "create_delivery_for_topic/2 with no data creates a event in the dead letter events table" do
      topic = insert(:topic)
      destination = insert(:destination, topic: topic)
      event = insert(:event, topic: topic)
      ER.Destinations.Delivery.create_table!(topic)

      attrs = %{
        event_id: event.id,
        destination_id: destination.id,
        status: :success
      }

      assert {:ok, %Delivery{} = delivery} =
               Destinations.create_delivery_for_topic(topic.name, attrs)

      assert Ecto.get_meta(delivery, :source) ==
               "#{topic.name}_deliveries"

      ER.Destinations.Delivery.drop_table!(topic)
    end

    test "create_delivery_for_topic/2 when the topic delivery table does not exist it returns an error tuple" do
      topic = insert(:topic)
      destination = insert(:destination, topic: topic)
      event = insert(:event, topic: topic)

      attrs = %{
        event_id: event.id,
        destination_id: destination.id,
        status: :success
      }

      assert {:error, reason} = Destinations.create_delivery_for_topic(topic.name, attrs)

      assert reason ==
               "relation \"#{topic.name}_deliveries\" does not exist"
    end

    test "update_delivery/2 updates the delivery" do
      {:ok, topic} = Events.create_topic(%{name: "users"})

      attrs =
        params_for(:event,
          topic: topic
        )

      {:ok, event} = Events.create_event_for_topic(attrs)

      destination = insert(:destination, topic: topic)

      attrs = %{
        event_id: event.id,
        destination_id: destination.id,
        status: :pending
      }

      {:ok, delivery} = Destinations.create_delivery_for_topic(topic.name, attrs)

      {:ok, delivery} =
        Destinations.update_delivery(delivery, %{
          status: :success,
          attempts: [%{"response" => "attempt"}]
        })

      assert delivery.status == :success
      assert delivery.attempts == [%{"response" => "attempt"}]
    end

    test "update_delivery/2 with valid data updates the delivery" do
      event = insert(:event)
      delivery = insert(:delivery, event_id: event.id)
      update_attrs = %{attempts: []}

      assert {:ok, %Delivery{} = delivery} = Destinations.update_delivery(delivery, update_attrs)
      assert delivery.attempts == []
    end

    test "update_delivery/2 with invalid data returns error changeset" do
      delivery = insert(:delivery)
      assert {:error, %Ecto.Changeset{}} = Destinations.update_delivery(delivery, @invalid_attrs)

      assert delivery ==
               Destinations.get_delivery!(delivery.id)
               |> Repo.preload(destination: [:topic])
    end

    test "delete_delivery/1 deletes the delivery" do
      delivery = insert(:delivery)
      assert {:ok, %Delivery{}} = Destinations.delete_delivery(delivery)
      assert_raise Ecto.NoResultsError, fn -> Destinations.get_delivery!(delivery.id) end
    end

    test "change_delivery/1 returns a delivery changeset" do
      delivery = insert(:delivery)
      assert %Ecto.Changeset{} = Destinations.change_delivery(delivery)
    end
  end

  describe "list_deliveries_for_destination/2" do
    setup [:setup_topic, :setup_deliveries]

    test "list_deliveries_for_destination/2 returns all pending deliveries for a destination",
         %{
           topic: topic,
           destination: destination,
           pending_delivery: pending_delivery,
           pending_delivery_2: pending_delivery_2,
           successful_delivery: successful_delivery
         } do
      pending_delivery_ids =
        Enum.map(
          Destinations.list_deliveries_for_destination(
            topic.name,
            destination.id,
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
           destination: destination,
           pending_delivery: pending_delivery,
           pending_delivery_2: pending_delivery_2
         } do
      deliveries =
        Destinations.list_deliveries_for_destination(
          topic.name,
          destination.id,
          status: :pending
        )

      Destinations.update_all_deliveries(topic.name, deliveries, set: [status: "success"])

      deliveries =
        Destinations.list_deliveries_for_destination(
          topic.name,
          destination.id,
          status: :success
        )

      successful_delivery_ids = Enum.map(deliveries, & &1.id)

      assert pending_delivery.id in successful_delivery_ids
      assert pending_delivery_2.id in successful_delivery_ids

      assert Enum.all?(deliveries, &(&1.status == :success))
    end
  end
end
