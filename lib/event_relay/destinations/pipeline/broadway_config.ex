defmodule ER.Destinations.Pipeline.BroadwayConfig do
  defstruct processor_concurrency: 10,
            processor_min_demand: 1,
            processor_max_demand: 50,
            batcher_concurrency: 1,
            batch_size: 50,
            batch_timeout: 1000,
            name: nil,
            destination: nil,
            pull_interval: 1000

  alias __MODULE__

  def new(broadway_config \\ %{}) do
    struct(BroadwayConfig, broadway_config)
  end
end
