defmodule ERWeb.EventsChannelTest do
  use ERWeb.ChannelCase

  import ER.Factory
  import Mox

  setup :verify_on_exit!

  setup do
    producer_api_key = insert(:api_key, type: :producer)
    consumer_api_key = insert(:api_key)
    topic = insert(:topic)
    subscription = insert(:subscription, topic: topic)
    insert(:api_key_subscription, api_key: producer_api_key, subscription: subscription)
    insert(:api_key_topic, api_key: producer_api_key, topic: topic)

    {:ok, producer_token} = ER.JWT.Token.build(producer_api_key)
    {:ok, consumer_token} = ER.JWT.Token.build(consumer_api_key)

    expect(ER.Events.ChannelCacheBehaviorMock, :register_socket, fn _pid, _subscription_id ->
      1
    end)

    ER.Events.Event.create_table!(topic)
    ER.Subscriptions.Delivery.create_table!(topic)

    {:ok, _, socket} =
      ERWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(ERWeb.EventsChannel, "events:#{subscription.id}", %{
        "producer_token" => producer_token,
        "consumer_token" => consumer_token
      })

    %{socket: socket, topic: topic, subscription: subscription}
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

    ref = push(socket, "publish_events", request)
    assert_reply ref, :ok, %{status: "ok"}

    events = ER.Events.list_events_for_topic(topic_name: topic.name)
    assert length(events) == 1
  end
end
