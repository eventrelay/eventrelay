defmodule ER.MetricsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ER.Metrics` context.
  """

  @doc """
  Generate a metric.
  """
  def metric_fixture(attrs \\ %{}) do
    {:ok, metric} =
      attrs
      |> Enum.into(%{
        field_path: "some field_path",
        filters: %{},
        name: "some name",
        type: "some type"
      })
      |> ER.Metrics.create_metric()

    metric
  end
end
