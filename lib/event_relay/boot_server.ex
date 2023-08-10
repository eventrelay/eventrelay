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
    unless ER.test?() do
      Process.send_after(self(), :boot, 10)
    end

    {:noreply, state}
  end

  def handle_info(:boot, state) do
    Logger.debug("BootServer.boot on node=#{inspect(Node.self())}")

    unless Code.ensure_loaded?(IEx) and IEx.started?() do
      Horde.DynamicSupervisor.start_child(
        ER.Horde.Supervisor,
        {ER.Subscriptions.Manager.Server, [name: "subscriptions_manager"]}
      )

      # TODO: improve supervision
      ER.Ingestors.list_ingestors()
      |> Enum.each(fn ingestor ->
        ER.Ingestors.Ingestor.start_ingestor(ingestor)
      end)
    end

    # TODO: needs to load all the deliveries that care still in progress

    {:noreply, state}
  end

  def init(args) do
    {:ok, args, {:continue, :init_children}}
  end
end
