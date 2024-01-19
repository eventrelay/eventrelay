defmodule ER.Destinations.Manager.Server do
  @moduledoc """
  Manages all the destination servers
  """
  use GenServer
  use ER.Server
  require Logger
  alias ER.Destinations
  alias ER.Destinations.Destination
  alias Phoenix.PubSub

  def handle_continue(:load_state, state) do
    PubSub.subscribe(ER.PubSub, "destination:created")
    PubSub.subscribe(ER.PubSub, "destination:updated")
    PubSub.subscribe(ER.PubSub, "destination:deleted")

    destinations = ER.Destinations.list_destinations()

    children =
      Enum.map(destinations, fn dest ->
        build_destination_spec(dest)
      end)
      |> Enum.reject(&is_nil/1)

    pid =
      case Supervisor.start_link(children,
             name: ER.Destinations.Manager.Supervisor,
             strategy: :one_for_one
           ) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
        _ -> nil
      end

    state = Map.put(state, :supervisor, pid)

    {:noreply, state}
  end

  def find_child_by_destination(pid, destination) do
    Supervisor.which_children(pid)
    |> Enum.find(fn {id, _, _, _} ->
      String.contains?(id, destination.id)
    end)
  end

  def build_destination_spec(%Destination{paused: true} = destination) do
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

  def start_destination_pipeline(supervisor, id) when is_binary(id) do
    destination = Destinations.get_destination(id)
    start_destination_pipeline(supervisor, destination)
  end

  def start_destination_pipeline(supervisor, %Destination{} = destination)
      when is_pid(supervisor) do
    child = build_destination_spec(destination)

    if child do
      Supervisor.start_child(supervisor, child)
    end
  end

  def start_destination_pipeline(supervisor, destination) do
    Logger.info(
      "Cannot start ER.Destinations.Pipeline because the detination is invalid. destination=#{inspect(destination)}, supervisor=#{inspect(supervisor)}"
    )

    nil
  end

  def stop_destination_pipeline(supervisor, %Destination{} = destination)
      when is_pid(supervisor) do
    child = find_child_by_destination(supervisor, destination)

    if child do
      child_id = elem(child, 0)
      Supervisor.terminate_child(supervisor, child_id)
      Supervisor.delete_child(supervisor, child_id)
    end
  end

  def stop_destination_pipeline(destination) do
    Logger.info(
      "Cannot stop ER.Destinations.Pipeline because the detination is invalid. detination=#{inspect(destination)}"
    )
  end

  def handle_info({:destination_created, destination}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:destination_created, #{inspect(destination)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    start_destination_pipeline(state.supervisor, destination)
    {:noreply, state}
  end

  def handle_info({:destination_updated, destination}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:destination_updated, #{inspect(destination)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    stop_destination_pipeline(state.supervisor, destination)
    start_destination_pipeline(state.supervisor, destination)
    {:noreply, state}
  end

  def handle_info({:destination_deleted, destination}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:destination_deleted, #{inspect(destination)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    stop_destination_pipeline(state.supervisor, destination)
    {:noreply, state}
  end

  def handle_terminate(_reason, _state) do
    :ok
  end

  def name(id) do
    "destination:#{id}"
  end
end
