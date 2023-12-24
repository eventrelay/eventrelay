defmodule ER.Destinations.Manager.Server do
  @moduledoc """
  Manages all the destination servers
  """
  use GenServer
  require Logger
  alias Phoenix.PubSub
  alias ER.Destinations.Destination

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
    PubSub.subscribe(ER.PubSub, "destination:created")
    PubSub.subscribe(ER.PubSub, "destination:updated")
    PubSub.subscribe(ER.PubSub, "destination:deleted")
    {:ok, args, {:continue, :load_state}}
  end

  def handle_continue(:load_state, state) do
    # get all the destinations and start the destination servers but
    # only if this is the primary node
    # TODO: need to figure out how to get the primary node
    destinations = ER.Destinations.list_destinations()

    Enum.each(destinations, fn destination ->
      ER.Destinations.Server.factory(destination.id)

      if Destination.s3?(destination) do
        # if we are an S3 destination spin up the server that syncs batches of deliveries to S3
        ER.Destinations.Delivery.S3.Server.factory(destination.id, %{
          "destination" => destination
        })
      end
    end)

    {:noreply, state}
  end

  def handle_info({:destination_created, destination_id}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:destination_created, #{inspect(destination_id)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    ER.Destinations.Server.factory(destination_id)
    {:noreply, state}
  end

  def handle_info({:destination_updated, destination_id}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:destination_updated, #{inspect(destination_id)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    ER.Destinations.Server.stop(destination_id)
    ER.Destinations.Server.factory(destination_id)
    {:noreply, state}
  end

  def handle_info({:destination_deleted, destination_id}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:destination_deleted, #{inspect(destination_id)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    ER.Destinations.Server.stop(destination_id)
    {:noreply, state}
  end

  def via_tuple(name) do
    {:via, Horde.Registry, {ER.Horde.Registry, name}}
  end
end
