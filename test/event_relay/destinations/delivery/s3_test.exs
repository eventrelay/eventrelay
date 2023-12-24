defmodule ER.Destinations.Delivery.S3Test do
  use ER.DataCase
  alias ER.Destinations.Delivery
  alias ER.Destinations.Delivery
  alias ER.Events.Event
  alias ER.Events
  alias ER.Repo

  import ER.Factory

  setup do
    destination = insert(:destination, destination_type: :s3)
    topic = insert(:topic, name: "test")
    Event.create_table!(topic)
    Delivery.create_table!(topic)

    event_params = params_for(:event, topic_name: topic.name)

    {:ok, event} = Events.create_event_for_topic(event_params)
    event = Repo.preload(event, :topic)

    on_exit(fn -> Event.drop_table!(topic) end)

    {:ok, destination: destination, event: event}
  end

  describe "push/2" do
    test "creates pending delivery", %{destination: destination, event: event} do
      push_destination = ER.Destinations.Push.Factory.build(destination)
      {:ok, delivery} = ER.Destinations.Push.Destination.push(push_destination, event)

      assert delivery.status == :pending
      assert delivery.destination_id == destination.id
      assert delivery.event_id == event.id
    end
  end
end
