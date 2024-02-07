defmodule ER.Destinations.Server do
  @moduledoc """
  Destination server
  """
  require Logger
  use GenServer
  use ER.Server.Base
  use ER.Horde.Server
  alias ER.Destinations.Destination
  import Flamel.Wrap

  def handle_continue(:load_state, %{destination: destination} = state) do
    destination
    |> start_supervisor(state)
    |> noreply()
  end

  def start_supervisor(destination, state) do
    destination
    |> build_destination_spec()
    |> then(fn
      nil ->
        state

      spec ->
        pid =
          case Supervisor.start_link([spec],
                 name: supervisor_name("destination:supervisor:#{destination.id}"),
                 strategy: :one_for_one
               ) do
            {:ok, pid} -> pid
            {:error, {:already_started, pid}} -> pid
            _ -> nil
          end

        Map.put(state, :pid, pid)
    end)
  end

  def restart(destination) do
    GenServer.cast(via(destination.id), {:restart, destination})
  end

  # We have a pid so the supervisor is running
  def handle_cast({:restart, destination}, %{pid: pid} = state) do
    case Supervisor.stop(pid) do
      :ok ->
        start_supervisor(destination, state)

      _ ->
        state
    end
    |> noreply()
  end

  # There is no pid for the supervisor so it is not started
  def handle_cast({:restart, destination}, state) do
    destination
    |> start_supervisor(state)
    |> noreply()
  end

  def supervisor_name(id) do
    Logger.debug("#{__MODULE__}.supervisor_name(#{inspect(id)})")
    {:via, Registry, {ER.Registry, id}}
  end

  def build_destination_spec(%Destination{paused: true}) do
    nil
  end

  def build_destination_spec(%Destination{paused: false} = destination) do
    case ER.Destinations.Pipeline.factory(destination) do
      nil ->
        Logger.info(
          "#{__MODULE__}.build_destination_pipeline(#{inspect(destination)} not starting pipline."
        )

        nil

      pipeline ->
        Logger.debug(
          "#{__MODULE__}.build_destination_pipeline(#{inspect(destination)} starting pipeline. pipeline=#{inspect(pipeline)}"
        )

        {pipeline, [destination: destination]}
    end
  end

  def handle_terminate(_reason, _state) do
    :ok
  end

  def name(id) do
    "destination:#{id}"
  end
end
