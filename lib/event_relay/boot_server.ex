defmodule ER.BootServer do
  @moduledoc """
  Handles starting other processes on application start up
  """
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def handle_continue(:init_children, state) do
    Process.send_after(self(), :boot, 10)
    {:noreply, state}
  end

  def handle_info(:boot, state) do
    Logger.info("BootServer.boot on node=#{inspect(Node.self())}")

    Horde.DynamicSupervisor.start_child(
      ER.Horde.Supervisor,
      {ER.SubscriptionsServer, [name: "subscriptions_server"]}
    )

    {:noreply, state}
  end

  def init(args) do
    {:ok, args, {:continue, :init_children}}
  end
end
