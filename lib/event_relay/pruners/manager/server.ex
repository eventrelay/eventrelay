defmodule ER.Pruners.Manager.Server do
  @moduledoc """
  Manages all the pruner servers
  """
  use GenServer
  require Logger
  use ER.Server
  alias Phoenix.PubSub

  def handle_continue(:load_state, state) do
    Logger.debug(
      "#{__MODULE__}.handle_continue(:load_state, #{inspect(state)}) loading pruner manager server"
    )

    PubSub.subscribe(ER.PubSub, "pruner:created")
    PubSub.subscribe(ER.PubSub, "pruner:updated")
    PubSub.subscribe(ER.PubSub, "pruner:deleted")

    ER.Pruners.list_pruners()
    |> Enum.each(fn pruner ->
      ER.Pruners.Server.factory(pruner.id)
    end)

    {:noreply, state}
  end

  def handle_info({:pruner_created, pruner_id}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:pruner_created, #{inspect(pruner_id)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    ER.Pruners.Server.factory(pruner_id)
    {:noreply, state}
  end

  def handle_info({:pruner_updated, pruner_id}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:pruner_updated, #{inspect(pruner_id)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    ER.Pruners.Server.stop(pruner_id)
    ER.Pruners.Server.factory(pruner_id)
    {:noreply, state}
  end

  def handle_info({:pruner_deleted, pruner_id}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:pruner_deleted, #{inspect(pruner_id)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    ER.Pruners.Server.stop(pruner_id)
    {:noreply, state}
  end

  def handle_terminate(_reason, _state) do
    :ok
  end

  def name(id) do
    "pruner:#{id}"
  end
end
