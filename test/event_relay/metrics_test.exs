defmodule ER.MetricsTest do
  use ER.DataCase

  import ER.Factory
  alias ER.Metrics

  describe "metrics" do
    alias ER.Metrics.Metric

    import ER.MetricsFixtures

    @invalid_attrs %{field_path: nil, filters: nil, name: nil, type: :sum}

    test "list_metrics/0 returns all metrics" do
      metric = insert(:metric)
      assert Metrics.list_metrics() == [metric]
    end

    test "get_metric!/1 returns the metric with given id" do
      metric = insert(:metric)
      assert Metrics.get_metric!(metric.id) == metric
    end

    test "create_metric/1 with valid data creates a metric" do
      valid_attrs = %{
        field_path: "some field_path",
        filters: [],
        name: "some sum",
        type: :sum
      }

      assert {:ok, %Metric{} = metric} = Metrics.create_metric(valid_attrs)
      assert metric.field_path == "some field_path"
      assert metric.filters == []
      assert metric.name == "some sum"
      assert metric.type == :sum
    end

    test "create_metric/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Metrics.create_metric(@invalid_attrs)
    end

    test "update_metric/2 with valid data updates the metric" do
      metric = insert(:metric)

      update_attrs = %{
        field_path: "some updated field_path",
        filters: [],
        name: "some updated name",
        type: :sum
      }

      assert {:ok, %Metric{} = metric} = Metrics.update_metric(metric, update_attrs)
      assert metric.field_path == "some updated field_path"
      assert metric.filters == []
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
end
