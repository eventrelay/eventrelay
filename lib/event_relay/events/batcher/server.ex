defmodule ER.Events.Batcher.Server do
  @moduledoc """
  This server is responsible for gathering events and writing them to Postgres in batches
  """
  use GenServer
  use ER.Server.Base
  use ER.Horde.Server
  require Logger
  import Flamel.Wrap
  alias ER.Events.Event
  alias ER.Repo

  @drain_interval_ms 1_000

  @max_batch_size 2_500

  def handle_continue(:load_state, state) do
    Process.flag(:trap_exit, true)

    state
    |> Map.put(:id, state["id"])
    |> Map.put(:batch, [])
    |> Map.put(:timer, schedule_next_tick())
    |> noreply()
  end

  def add(id, events) do
    GenServer.cast(via(id), {:add, events})
    ok(events)
  end

  def drain(id) do
    GenServer.call(via(id), :drain, :infinity)
  end

  def handle_cast({:add, events}, %{id: topic_name, batch: batch} = state) do
    new_batch =
      Enum.reduce(events, batch, fn item, acc ->
        [item | acc]
      end)

    if length(new_batch) >= @max_batch_size do
      Process.cancel_timer(state[:timer])
      do_drain(topic_name, new_batch)
      noreply(%{id: topic_name, batch: [], timer: schedule_next_tick()})
    else
      noreply(%{state | batch: new_batch})
    end
  end

  def handle_call(:drain, _from, %{id: topic_name, batch: batch} = state) do
    Process.cancel_timer(state[:timer])
    do_drain(topic_name, batch)
    reply(batch, %{id: topic_name, batch: [], timer: schedule_next_tick()})
  end

  def handle_info(:tick, %{id: topic_name, batch: batch}) do
    do_drain(topic_name, batch)
    noreply(%{id: topic_name, batch: [], timer: schedule_next_tick()})
  end

  def terminate(_reason, %{id: topic_name, batch: batch}) do
    do_drain(topic_name, batch)
  end

  defp do_drain(topic_name, batch) do
    case batch do
      [] ->
        nil

      events ->
        Logger.debug("Send batched events to Postgres for #{inspect(topic_name)}")
        insert_all(topic_name, events)
    end
  end

  defp insert_all(topic_name, events) do
    now = DateTime.utc_now()

    placeholders =
      %{inserted_at: now, updated_at: now}

    {valid, invalid} =
      Enum.reduce(events, {[], []}, fn attrs, {valid, invalid} ->
        attrs
        |> Event.apply_defaults()
        |> then(fn attrs ->
          Event.changeset(%Event{}, attrs)
        end)
        |> then(fn cs ->
          case Ecto.Changeset.apply_action(cs, :insert) do
            # this is also going to reverse the list for us which we need to do
            {:ok, _} ->
              {[Event.prepare_for_batched_insert(cs.changes) | valid], invalid}

            {:error, _} ->
              {valid, [Event.prepare_for_batched_insert(cs.changes) | invalid]}
          end
        end)
      end)

    insert_all({Event.table_name(topic_name), Event}, valid, placeholders)
    insert_all({"dead_letter_events", Event}, invalid, placeholders)
  end

  defp insert_all(source, [], placeholders)
       when is_tuple(source) and is_map(placeholders) do
    :ok
  end

  defp insert_all(source, events, placeholders)
       when is_tuple(source) and is_list(events) and is_map(placeholders) do
    Repo.insert_all(source, events, placeholders: placeholders)
    :ok
  end

  defp schedule_next_tick() do
    Process.send_after(self(), :tick, @drain_interval_ms)
  end

  def name(id) do
    "events:batcher:#{id}"
  end
end
