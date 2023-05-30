defmodule ERWeb.Grpc.EventRelay.ServerTest do
  use ER.DataCase

  alias ERWeb.Grpc.EventRelay.Server
  alias ER.Events

  alias ERWeb.Grpc.Eventrelay.{
    PublishEventsRequest,
    NewEvent
    # PublishEventsResponse,
    # ListTopicsResponse,
    # Topic,
    # CreateTopicResponse,
    # CreateSubscriptionResponse,
    # CreateSubscriptionRequest,
    # Subscription,
    # DeleteSubscriptionResponse,
    # DeleteSubscriptionRequest,
    # ListSubscriptionsResponse,
    # ListSubscriptionsRequest,
    # PullEventsRequest,
    # PullEventsResponse,
    # CreateApiKeyRequest,
    # CreateApiKeyResponse,
    # ApiKey,
    # RevokeApiKeyRequest,
    # RevokeApiKeyResponse,
    # AddSubscriptionsToApiKeyRequest,
    # AddSubscriptionsToApiKeyResponse,
    # DeleteSubscriptionsFromApiKeyRequest,
    # DeleteSubscriptionsFromApiKeyResponse,
    # AddTopicsToApiKeyResponse,
    # AddTopicsToApiKeyRequest,
    # DeleteTopicsFromApiKeyRequest,
    # DeleteTopicsFromApiKeyResponse,
    # CreateJWTRequest,
    # CreateJWTResponse
  }

  setup do
    {:ok, topic} = Events.create_topic(%{name: "audit_log"})

    {:ok, topic: topic}
  end

  describe "publish_events/1" do
    test "publishes events", %{topic: topic} do
      event_name = "entry.created"
      group_key = "groupkey"

      request = %PublishEventsRequest{
        topic: topic.name,
        durable: true,
        events: [
          %NewEvent{
            name: event_name,
            data: Jason.encode!(%{}),
            source: "test",
            group_key: group_key
          }
        ]
      }

      result = Server.publish_events(request, nil)

      [event | _] = result.events

      assert event.name == event_name
      assert event.group_key == group_key

      events = Events.list_events_for_topic(topic_name: topic.name)
      assert Enum.count(events) == 1
    end

    test "raise RPCError if no topic is provided" do
      event_name = "entry.created"
      group_key = "groupkey"

      request = %PublishEventsRequest{
        durable: true,
        events: [
          %NewEvent{
            name: event_name,
            data: Jason.encode!(%{}),
            source: "test",
            group_key: group_key
          }
        ]
      }

      assert_raise GRPC.RPCError, "A topic must be provided to publish_events", fn ->
        Server.publish_events(request, nil)
      end
    end

    test "does not persit events if durable is false", %{topic: topic} do
      event_name = "entry.created"
      group_key = "groupkey"

      request = %PublishEventsRequest{
        topic: topic.name,
        durable: false,
        events: [
          %NewEvent{
            name: event_name,
            data: Jason.encode!(%{}),
            source: "test",
            group_key: group_key
          }
        ]
      }

      Server.publish_events(request, nil)
      events = Events.list_events_for_topic(topic_name: topic.name)
      assert Enum.count(events) == 0
    end
  end
end
