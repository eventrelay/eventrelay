defmodule ER.MetricsTest do
  use ER.DataCase

  import ER.Factory
  alias ER.Metrics

  setup do
    {:ok, topic} = ER.Events.create_topic(%{name: "log"})

    {:ok, topic: topic}
  end

  describe "metrics" do
    alias ER.Metrics.Metric

    @invalid_attrs %{field_path: nil, query: nil, name: nil, type: :sum}

    test "list_metrics/0 returns all metrics" do
      metric = insert(:metric)
      assert Metrics.list_metrics() == [metric]
    end

    test "get_metric!/1 returns the metric with given id" do
      metric = insert(:metric)
      assert Metrics.get_metric!(metric.id) == metric
    end

    test "create_metric/1 with valid data creates a metric", %{topic: topic} do
      valid_attrs = %{
        field_path: "some field_path",
        query: "data.first_name == 'Sarah'",
        name: "some sum",
        type: :sum,
        topic_name: topic.name
      }

      assert {:ok, %Metric{} = metric} = Metrics.create_metric(valid_attrs)
      assert metric.field_path == "some field_path"
      assert metric.query == "data.first_name == 'Sarah'"
      assert metric.name == "some sum"
      assert metric.type == :sum
    end

    test "create_metric/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Metrics.create_metric(@invalid_attrs)
    end

    test "update_metric/2 with valid data updates the metric", %{topic: topic} do
      metric = insert(:metric)

      update_attrs = %{
        field_path: "some updated field_path",
        query: "data.first_name == 'Sarah'",
        name: "some updated name",
        type: :sum,
        topic_name: topic.name
      }

      assert {:ok, %Metric{} = metric} = Metrics.update_metric(metric, update_attrs)
      assert metric.field_path == "some updated field_path"
      assert metric.query == "data.first_name == 'Sarah'"
      assert metric.name == "some updated name"
      assert metric.type == :sum
    end

    test "update_metric/2 with invalid data returns error changeset" do
      metric = insert(:metric)
      assert {:error, %Ecto.Changeset{}} = Metrics.update_metric(metric, @invalid_attrs)
      assert metric == Metrics.get_metric!(metric.id)
    end

    test "delete_metric/1 deletes the metric" do
      metric = insert(:metric)
      assert {:ok, %Metric{}} = Metrics.delete_metric(metric)
      assert_raise Ecto.NoResultsError, fn -> Metrics.get_metric!(metric.id) end
    end

    test "change_metric/1 returns a metric changeset" do
      metric = insert(:metric)
      assert %Ecto.Changeset{} = Metrics.change_metric(metric)
    end
  end

  describe "build_events_for_metric_udpate/3" do
    test "returns list of events for metric updates", %{topic: topic} do
      first_metric =
        insert(:metric, topic_name: topic.name, type: :sum, field_path: "data.cart.total")

      last_metric = insert(:metric, topic_name: topic.name, type: :count)

      totals = [10, 30]

      Enum.each(totals, fn total ->
        attrs = params_for(:event, topic: topic)
        attrs = %{attrs | data: %{"cart" => %{"total" => total}}}
        ER.Events.create_event_for_topic(attrs)
      end)

      events =
        ER.Metrics.build_metric_updates(
          topic_name: topic.name,
          topic_identifier: nil
        )
        |> Enum.map(&elem(&1, 1))

      first_event = List.first(events)
      assert first_event.data["metric"]["name"] == first_metric.name
      assert first_event.data["metric"]["type"] == to_string(first_metric.type)
      assert first_event.source == "event_relay"
      assert first_event.topic_name == topic.name

      last_event = List.last(events)
      assert last_event.data["metric"]["name"] == last_metric.name
      assert last_event.data["metric"]["type"] == to_string(last_metric.type)
      assert last_event.source == "event_relay"
      assert last_event.topic_name == topic.name
    end
  end
end
