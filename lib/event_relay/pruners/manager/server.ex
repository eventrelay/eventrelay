defmodule ER.Pruners.Manager.Server do
  @moduledoc """
  Manages all the pruner servers
  """
  use GenServer
  require Logger
  alias Phoenix.PubSub

  def child_spec(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    %{
      id: "#{__MODULE__}_#{name}",
      start: {__MODULE__, :start_link, [name]},
      shutdown: 60_000,
      restart: :transient
    }
  end

  def start_link(name) do
    case GenServer.start_link(__MODULE__, %{}, name: via_tuple(name)) do
      {:ok, pid} ->
        Logger.debug("#{__MODULE__}.start_link: starting #{via_tuple(name)}")
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.debug("#{__MODULE__} already started at #{inspect(pid)}, returning :ignore")
        :ignore

      :ignore ->
        Logger.debug("#{__MODULE__}.start_link :ignore")
    end
  end

  def init(args) do
    PubSub.subscribe(ER.PubSub, "pruner:created")
    PubSub.subscribe(ER.PubSub, "pruner:updated")
    PubSub.subscribe(ER.PubSub, "pruner:deleted")
    {:ok, args, {:continue, :load_state}}
  end

  def handle_continue(:load_state, state) do
    pruners = ER.Pruners.list_pruners()

    Enum.each(pruners, fn pruner ->
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

  def via_tuple(name) do
    {:via, Horde.Registry, {ER.Horde.Registry, name}}
  end
end
