defmodule ER.NodeListener do
  @moduledoc """
  Handles listening for Elixir nodes. 
  """
  use GenServer
  require Logger
  def start_link(_), do: GenServer.start_link(__MODULE__, [])

  def init(_) do
    :net_kernel.monitor_nodes(true, node_type: :visible)
    {:ok, nil}
  end

  def handle_info({:nodeup, _node, _node_type}, state) do
    {:noreply, state}
  end

  def handle_info({:nodedown, _node, _node_type}, state) do
    {:noreply, state}
  end
end
