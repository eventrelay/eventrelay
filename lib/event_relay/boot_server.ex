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
    # we want this to start as soon as possible
    ER.Events.Batcher.Manager.Server.factory("manager")

    unless Code.ensure_loaded?(IEx) and IEx.started?() do
      unless ER.Env.disable_push_destinations?() do
        ER.Destinations.Manager.Server.factory("destinations:manager")
      end

      ER.Pruners.Manager.Server.factory("pruners:manager")

      ER.Sources.list_sources()
      |> Enum.each(fn source ->
        ER.Sources.Source.start_source(source)
      end)

      ER.Sources.list_sources()
      |> Enum.each(fn source ->
        ER.Sources.Source.start_source(source)
      end)

      ER.Transformers.list_transformers()
      |> Enum.each(fn transformer ->
        ER.Transformers.factory(transformer)
        |> ER.Transformers.Transformation.precompile()
      end)
    end

    {:noreply, state}
  end

  def init(args) do
    {:ok, args, {:continue, :init_children}}
  end
end
