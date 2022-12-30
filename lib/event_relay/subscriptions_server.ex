defmodule ER.SubscriptionsServer do
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
        Logger.info("#{__MODULE__}.start_link: starting #{via_tuple(name)}")
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("#{__MODULE__} already started at #{inspect(pid)}, returning :ignore")
        :ignore

      :ignore ->
        Logger.info("#{__MODULE__}.start_link :ignore")
    end
  end

  def init(args) do
    PubSub.subscribe(ER.PubSub, "subscription:created")
    {:ok, args}
  end

  def via_tuple(name) do
    {:via, Horde.Registry, {ER.Horde.Registry, name}}
  end
end
