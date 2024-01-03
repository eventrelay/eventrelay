defmodule ER.Destinations.Pipeline.Test do
  use ER.Destinations.Pipeline.Base

  def name(id) do
    "test:#{id}"
  end
end

defmodule ER.Destinations.Pipeline.BaseTest do
  use ER.DataCase
  import ER.Factory

  describe "get_broadway_config/1" do
    setup do
      destination = insert(:destination)
      {:ok, destination: destination}
    end

    test "returns BroadwayConfig with defaults", %{
      destination: destination
    } do
      config = ER.Destinations.Pipeline.Test.get_broadway_config(destination)
      assert config.processor_concurrency == 10
      assert config.batcher_concurrency == 1
      assert config.batch_size == 50
      assert config.batch_timeout == 1000

      refute config.name == nil
      refute config.destination == nil
    end
  end
end
