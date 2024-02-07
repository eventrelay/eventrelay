defmodule ER.Destinations.Manager.Server do
  @moduledoc """
  Manages all the destination servers
  """
  require Logger
  use GenServer
  use ER.Server.Base
  use ER.Horde.Server
  alias Phoenix.PubSub

  def handle_continue(:load_state, state) do
    PubSub.subscribe(ER.PubSub, "destination:created")
    PubSub.subscribe(ER.PubSub, "destination:updated")
    PubSub.subscribe(ER.PubSub, "destination:deleted")

    ER.Destinations.list_destinations()
    |> Enum.each(&ER.Destinations.Server.factory(&1.id, %{destination: &1}))

    {:noreply, state}
  end

  def handle_info({:destination_created, destination}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:destination_created, #{inspect(destination)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    ER.Destinations.Server.factory(destination.id, %{destination: destination})
    {:noreply, state}
  end

  def handle_info({:destination_updated, destination}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:destination_updated, #{inspect(destination)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    ER.Destinations.Server.restart(destination)
    {:noreply, state}
  end

  def handle_info({:destination_deleted, destination}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:destination_deleted, #{inspect(destination)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    ER.Destinations.Server.stop(destination.id)
    {:noreply, state}
  end

  def handle_terminate(_reason, _state) do
    :ok
  end

  def name(id) do
    "destination:#{id}"
  end
end
