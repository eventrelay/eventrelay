defmodule ER.Destinations.Server do
  @moduledoc """
  Destination server
  """
  require Logger
  use GenServer
  use ER.Server.Base
  use ER.Horde.Server
  alias ER.Destinations.Destination

  def handle_continue(:load_state, %{destination: destination} = state) do
    destination
    |> build_destination_spec()
    |> then(fn
      nil ->
        nil

      spec ->
        case Supervisor.start_link([spec],
               name: supervisor_name("destination:supervisor:#{destination.id}"),
               strategy: :one_for_one
             ) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
          _ -> nil
        end
    end)

    {:noreply, state}
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
