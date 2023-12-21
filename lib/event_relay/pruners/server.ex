defmodule ER.Pruners.Server do
  @moduledoc """
  Handles pruning events
  """
  require Logger
  use GenServer
  use ER.Server

  # @default_tick_interval 5 * 60 * 1_000
  @default_tick_interval 1_000

  def handle_continue(:load_state, %{"id" => id} = state) do
    pruner = ER.Pruners.get_pruner!(id)

    timer = schedule_next_tick()

    state =
      state
      |> Map.put(:pruner, pruner)
      |> Map.put(:timer, timer)
      |> Map.put(:worker_task, nil)

    {:noreply, state}
  end

  # The worker task has finished and we need to reset it
  def handle_info({ref, _}, %{worker_task: %{ref: ref}} = state) do
    {:noreply, %{state | worker_task: nil}}
  end

  # No worker task so lets create one
  def handle_info(:tick, %{pruner: pruner, worker_task: nil} = state) do
    worker_task =
      Task.async(fn ->
        prune_events(pruner)
      end)

    timer = schedule_next_tick()

    {:noreply, %{state | timer: timer, worker_task: worker_task}}
  end

  # We will be here if the worker task has not completed is work
  # So we just schedule the next tick
  def handle_info(:tick, state) do
    timer = schedule_next_tick()

    {:noreply, %{state | timer: timer}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def prune_events(
        %{type: :time, topic_name: topic_name, query: query, config: %{"max_age" => max_age}} =
          pruner
      ) do
    Logger.debug("#{__MODULE__}.prune_events(#{inspect(pruner)}) on node=#{inspect(Node.self())}")
    datetime = DateTime.utc_now() |> DateTime.add(max_age * -1, :second)
    ER.Events.delete_events_for_topic_before(topic_name, datetime, query)
  end

  def prune_events(
        %{type: :count, topic_name: topic_name, query: query, config: %{"max_count" => max_count}} =
          pruner
      ) do
    Logger.debug("#{__MODULE__}.prune_events(#{inspect(pruner)}) on node=#{inspect(Node.self())}")
    ER.Events.delete_events_for_topic_over(topic_name, max_count, query)
  end

  def prune_events(pruner) do
    Logger.info("Can't prune events because of configuration issue pruner=#{inspect(pruner)}")
  end

  def handle_terminate(reason, %{timer: timer} = state) do
    Logger.debug("Pruner server terminated: #{inspect(reason)}")
    Logger.debug("Pruner server state: #{inspect(state)}")
    timer && Process.cancel_timer(timer)

    if state.worker_task do
      Task.shutdown(state.worker_task, :brutal_kill)
    end
  end

  def tick_interval() do
    @default_tick_interval
  end

  @spec name(binary()) :: binary()
  def name(id) do
    "pruner:" <> id
  end
end
