defmodule ERWeb.EventsChannelTest do
  use ERWeb.ChannelCase

  import ER.Factory
  use Mimic

  setup do
    api_key = insert(:api_key, type: :producer_consumer)
    topic = insert(:topic)
    destination = insert(:destination, topic: topic)
    insert(:api_key_destination, api_key: api_key, destination: destination)
    insert(:api_key_topic, api_key: api_key, topic: topic)

    {:ok, token} = ER.JWT.Token.build(api_key)

    expect(ER.Events.ChannelCache, :register_socket, fn _pid, _destination_id ->
      nil
    end)

    ER.Events.Event.create_table!(topic)
    ER.Destinations.Delivery.create_table!(topic)

    {:ok, _, socket} =
      ERWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(ERWeb.EventsChannel, "events:#{destination.id}", %{
        "token" => token
      })

    %{socket: socket, topic: topic, destination: destination}
  end

  test "publishes events", %{socket: socket, topic: topic} do
    request = %{
      "topic" => topic.name,
      "durable" => true,
      "events" => [
        %{
          "name" => "user.created",
          "data" => "{\"first_name\": \"Thomas\"}",
          "source" => "websocket",
          "context" => %{"ip_address" => "127.0.0.1"}
        }
      ]
    }

    events = ER.Events.list_events_for_topic(topic.name, return_batch: false)
    assert events == []

    ref = push(socket, "publish_events", request)
    assert_reply ref, :ok, %{status: "ok"}

    events = ER.Events.list_events_for_topic(topic.name, return_batch: false)
    assert length(events) == 1
  end

  test "publishes non durable events", %{socket: socket, topic: topic} do
    request = %{
      "topic" => topic.name,
      "durable" => "false",
      "events" => [
        %{
          "name" => "user.created",
          "data" => "{\"first_name\": \"Thomas\"}",
          "source" => "websocket",
          "context" => %{"ip_address" => "127.0.0.1"}
        }
      ]
    }

    events = ER.Events.list_events_for_topic(topic.name, return_batch: false)
    assert events == []

    ref = push(socket, "publish_events", request)
    assert_reply ref, :ok, %{status: "ok"}

    events = ER.Events.list_events_for_topic(topic.name, return_batch: false)
    assert events == []
  end
end
