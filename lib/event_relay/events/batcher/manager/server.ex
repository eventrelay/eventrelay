defmodule ER.Events.Batcher.Manager.Server do
  @moduledoc """
  This server handles managing the batch servers that to be inserted into the database.
  """
  use GenServer
  use ER.Server.Base
  use ER.Horde.Server
  require Logger
  import Flamel.Wrap

  alias Phoenix.PubSub

  def handle_continue(:load_state, state) do
    Logger.debug(
      "#{__MODULE__}.handle_continue(:load_state, #{inspect(state)}) loading topic manager server"
    )

    PubSub.subscribe(ER.PubSub, "topic:created")
    PubSub.subscribe(ER.PubSub, "topic:deleted")

    Enum.each(ER.Events.list_topics(), &ER.Events.Batcher.Server.factory(&1.name))

    noreply(state)
  end

  def handle_info({:topic_created, topic}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:topic_created, #{inspect(topic)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    ER.Events.Batcher.Server.factory(topic.name)
    {:noreply, state}
  end

  def handle_info({:topic_deleted, topic}, state) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:topic_deleted, #{inspect(topic)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    ER.Events.Batcher.Server.stop(topic.name)
    {:noreply, state}
  end

  def handle_terminate(_reason, _state) do
    Enum.each(ER.Events.list_topics(), &ER.Events.Batcher.Server.stop(&1.name))
    :ok
  end

  def name(id) do
    "events:batcher:#{id}"
  end
end
