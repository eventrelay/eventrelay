defmodule ERWeb.Grpc.EventRelay.ServerTest do
  use ER.DataCase

  alias ERWeb.Grpc.EventRelay.Server
  alias ER.Events
  import ER.Factory

  alias ERWeb.Grpc.Eventrelay.{
    PublishEventsRequest,
    NewEvent,
    GetMetricValueRequest,
    CreateMetricRequest,
    EventFilter,
    NewMetric,
    DeleteMetricRequest
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

  alias ER.Events.EventFilter

  describe "publish_events/2" do
    setup do
      {:ok, topic} = Events.create_topic(%{name: "audit_log"})

      {:ok, topic: topic}
    end

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

  describe "get_metric_value/2" do
    setup do
      {:ok, topic} = Events.create_topic(%{name: "log"})

      {:ok, topic: topic}
    end

    test "get a count metric", %{topic: topic} do
      metric =
        insert(:metric, topic_name: topic.name, type: :count, field_path: "data.cart.total")

      ER.Events.create_event_for_topic(params_for(:event, topic: topic))
      ER.Events.create_event_for_topic(params_for(:event, topic: topic))

      request = %GetMetricValueRequest{
        id: metric.id
      }

      result = Server.get_metric_value(request, nil)

      events = Events.list_events_for_topic(topic_name: topic.name)
      assert Enum.count(events) == ER.to_integer(result.value)
    end

    test "get a sum metric", %{topic: topic} do
      metric = insert(:metric, topic_name: topic.name, type: :sum, field_path: "data.cart.total")

      totals = [10, 30]

      Enum.each(totals, fn total ->
        attrs = params_for(:event, topic: topic)
        attrs = %{attrs | data: %{"cart" => %{"total" => total}}}
        ER.Events.create_event_for_topic(attrs)
      end)

      request = %GetMetricValueRequest{
        id: metric.id
      }

      result = Server.get_metric_value(request, nil)

      assert ER.to_float(Enum.sum(totals)) == ER.to_float(result.value)
    end

    test "get a max metric", %{topic: topic} do
      metric = insert(:metric, topic_name: topic.name, type: :max, field_path: "data.cart.total")
      totals = [10, 30]

      Enum.each(totals, fn total ->
        attrs = params_for(:event, topic: topic)
        attrs = %{attrs | data: %{"cart" => %{"total" => total}}}
        ER.Events.create_event_for_topic(attrs)
      end)

      request = %GetMetricValueRequest{
        id: metric.id
      }

      result = Server.get_metric_value(request, nil)

      assert ER.to_float(Enum.max(totals)) == ER.to_float(result.value)
    end

    test "get a min metric", %{topic: topic} do
      metric = insert(:metric, topic_name: topic.name, type: :min, field_path: "data.cart.total")
      totals = [10, 30]

      Enum.each(totals, fn total ->
        attrs = params_for(:event, topic: topic)
        attrs = %{attrs | data: %{"cart" => %{"total" => total}}}
        ER.Events.create_event_for_topic(attrs)
      end)

      request = %GetMetricValueRequest{id: metric.id}

      result = Server.get_metric_value(request, nil)

      assert ER.to_float(Enum.min(totals)) == ER.to_float(result.value)
    end

    test "get a avg metric", %{topic: topic} do
      metric =
        insert(:metric,
          topic_name: topic.name,
          type: :avg,
          field_path: "data.cart.total",
          filters: [
            %EventFilter{field_path: "data.cart.kind", comparison: "equal", value: "completed"}
          ]
        )

      totals = [10, 30]

      Enum.each(totals, fn total ->
        attrs = params_for(:event, topic: topic)
        attrs = %{attrs | data: %{"cart" => %{"total" => total, "kind" => "completed"}}}
        ER.Events.create_event_for_topic(attrs)
      end)

      attrs = params_for(:event, topic: topic)
      attrs = %{attrs | data: %{"cart" => %{"total" => 100, "kind" => "uncompleted"}}}
      ER.Events.create_event_for_topic(attrs)

      request = %GetMetricValueRequest{
        id: metric.id
      }

      result = Server.get_metric_value(request, nil)

      assert ER.to_float(Enum.sum(totals) / Enum.count(totals)) == ER.to_float(result.value)
    end
  end

  describe "create_metric/2" do
    setup do
      {:ok, topic} = Events.create_topic(%{name: "log"})

      {:ok, topic: topic}
    end

    test "create a new metric", %{topic: topic} do
      request = %CreateMetricRequest{
        metric: %NewMetric{
          name: "Test Metric",
          field_path: "data.cart.total",
          topic_name: topic.name,
          type: :SUM,
          filters: [%EventFilter{field: "reference_key", comparison: "equal", value: "test"}]
        }
      }

      result = Server.create_metric(request, nil)

      refute ER.Metrics.get_metric(result.metric.id) == nil
    end

    test "deletes a metric", %{topic: topic} do
      metric = insert(:metric, topic_name: topic.name, type: :avg, field_path: "data.cart.total")

      request = %DeleteMetricRequest{
        id: metric.id
      }

      result = Server.delete_metric(request, nil)

      assert ER.Metrics.get_metric(result.metric.id) == nil
    end
  end
end
