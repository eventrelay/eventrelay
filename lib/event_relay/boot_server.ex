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
    boot()
    {:noreply, state}
  end

  def boot do
    Horde.DynamicSupervisor.start_child(
      ER.Horde.Supervisor,
      {ER.SubscriptionsServer, [name: "subscriptions_server"]}
    )
  end

  def init(args) do
    {:ok, args, {:continue, :init_children}}
  end
end
