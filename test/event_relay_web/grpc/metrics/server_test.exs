defmodule ERWeb.Grpc.EventRelay.Metrics.ServerTest do
  use ER.DataCase

  alias ERWeb.Grpc.EventRelay.Metrics.Server
  alias ER.Events
  import ER.Factory

  alias ERWeb.Grpc.Eventrelay.{
    GetMetricValueRequest,
    CreateMetricRequest,
    DeleteMetricRequest,
    ListMetricsRequest
  }

  setup do
    {:ok, topic} = Events.create_topic(%{name: "log"})

    {:ok, topic: topic}
  end

  describe "get_metric_value/2" do
    test "get a count metric", %{topic: topic} do
      metric =
        insert(:metric, topic_name: topic.name, type: :count, field_path: "data.cart.total")

      ER.Events.create_event_for_topic(params_for(:event, topic: topic))
      ER.Events.create_event_for_topic(params_for(:event, topic: topic))

      request = %GetMetricValueRequest{
        id: metric.id
      }

      result = Server.get_metric_value(request, nil)

      events = Events.list_events_for_topic(topic.name, return_batch: false)
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
          query: "data.cart.kind == 'completed'"
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
    test "create a new metric", %{topic: topic} do
      request = %CreateMetricRequest{
        name: "Test Metric",
        field_path: "data.cart.total",
        topic_name: topic.name,
        type: :SUM,
        query: "reference_key == 'test'"
      }

      result = Server.create_metric(request, nil)

      refute ER.Metrics.get_metric(result.metric.id) == nil
    end
  end

  describe "delete_metric/2" do
    test "deletes a metric", %{topic: topic} do
      metric = insert(:metric, topic_name: topic.name, type: :avg, field_path: "data.cart.total")

      request = %DeleteMetricRequest{
        id: metric.id
      }

      result = Server.delete_metric(request, nil)

      assert ER.Metrics.get_metric(result.metric.id) == nil
    end
  end

  describe "list_metrics/2" do
    test "list metrics", %{topic: topic} do
      metric = insert(:metric, topic_name: topic.name, type: :avg, field_path: "data.cart.total")
      insert(:metric, topic_name: topic.name, type: :sum, field_path: "data.cart.total")

      request = %ListMetricsRequest{
        topic: topic.name,
        query: "name == '#{metric.name}'"
      }

      result = Server.list_metrics(request, nil)
      assert Repo.aggregate(ER.Metrics.Metric, :count) == 2
      assert result.total_count == 1
    end
  end
end
