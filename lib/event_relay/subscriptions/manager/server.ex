defmodule ER.Subscriptions.Manager.Server do
  @moduledoc """
  Manages all the subscription servers
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
    PubSub.subscribe(ER.PubSub, "subscription:created")
    PubSub.subscribe(ER.PubSub, "subscription:deleted")
    {:ok, args, {:continue, :load_state}}
  end

  def handle_continue(:load_state, state) do
    # get all the subscriptions and start the subscription servers but
    # only if this is the primary node
    # TODO: need to figure out how to get the primary node
    subscriptions = ER.Subscriptions.list_subscriptions()

    Enum.each(subscriptions, fn subscription ->
      ER.Subscriptions.Server.factory(subscription.id)
    end)

    {:noreply, state}
  end

  def handle_info({:subscription_created, subscription_id}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:subscription_created, #{inspect(subscription_id)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    ER.Subscriptions.Server.factory(subscription_id)
    {:noreply, state}
  end

  def handle_info({:subscription_deleted, subscription_id}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:subscription_deleted, #{inspect(subscription_id)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    ER.Subscriptions.Server.stop(subscription_id)
    {:noreply, state}
  end

  def via_tuple(name) do
    {:via, Horde.Registry, {ER.Horde.Registry, name}}
  end
end
