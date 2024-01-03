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

    Enum.each(destinations, fn dest ->
      start_destination_pipeline(dest)
    end)

    {:noreply, state}
  end

  def start_destination_pipeline(id) when is_binary(id) do
    destination = Destinations.get_destination(id)
    start_destination_pipeline(destination)
  end

  def start_destination_pipeline(%Destination{} = destination) do
    case ER.Destinations.Pipeline.factory(destination) do
      nil ->
        Logger.info(
          "#{__MODULE__}.start_destination_pipeline(#{inspect(destination)} not starting pipline."
        )

      pipeline ->
        Logger.debug(
          "#{__MODULE__}.start_destination_pipeline(#{inspect(destination)} starting pipeline. pipeline=#{inspect(pipeline)}"
        )

        result =
          DynamicSupervisor.start_child(
            ER.DynamicSupervisor,
            {pipeline, [destination: destination]}
          )

        Logger.debug("#{__MODULE__}.start_destination_pipeline with result=#{inspect(result)}")
    end
  end

  def start_destination_pipeline(destination) do
    Logger.info(
      "Cannot start ER.Destinations.Pipeline because the detination is invalid. detination=#{inspect(destination)}"
    )
  end

  def stop_destination_pipeline(%Destination{} = destination) do
    case ER.Destinations.Pipeline.factory(destination) do
      nil ->
        Logger.info(
          "#{__MODULE__}.stop_destination_pipeline(#{inspect(destination)} not stopping pipline."
        )

      pipeline ->
        server = apply(pipeline, :via, [destination.id])

        case GenServer.whereis(server) do
          nil ->
            Logger.info(
              "#{__MODULE__}.stop_destination_pipeline(#{inspect(destination)} not stopping pipline because pipeline is not started."
            )

          _ ->
            Broadway.stop(server)
        end
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

    start_destination_pipeline(destination)
    {:noreply, state}
  end

  def handle_info({:destination_updated, destination}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:destination_updated, #{inspect(destination)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    stop_destination_pipeline(destination)
    start_destination_pipeline(destination)
    {:noreply, state}
  end

  def handle_info({:destination_deleted, destination}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:destination_deleted, #{inspect(destination)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    stop_destination_pipeline(destination)
    {:noreply, state}
  end

  def handle_terminate(_reason, _state) do
    :ok
  end

  def name(id) do
    "destination:#{id}"
  end
end
