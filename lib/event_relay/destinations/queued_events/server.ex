defmodule ER.Destinations.QueuedEvents.Server do
  @moduledoc """
  Manages the pull and unlocking queued events
  """
  require Logger
  use GenServer
  use ER.Server.Base
  use ER.Horde.Server
  alias ER.Events

  def handle_continue(:load_state, %{"id" => id} = state) do
    destination = ER.Destinations.get_destination!(id)

    state =
      state
      |> Map.put("destination", destination)

    Logger.debug("Queued Events server started for destination=#{inspect(id)}")

    {:noreply, state}
  end

  def pull_queued_events(id, batch_size) do
    GenServer.call(via(id), {:pull_queued_events, batch_size})
  end

  def unlocked_queued_events(id, event_ids) do
    GenServer.call(
      via(id),
      {:unlocked_queued_events, event_ids}
    )
  end

  # We are retrieving events through to queued events genserver to force the calls to be queued to allow use to properly update the destination locks to enforce a deliver once constraint via the API.  
  def handle_call(
        {:pull_queued_events, batch_size},
        _from,
        %{"destination" => destination} =
          state
      ) do
    # get the events
    events =
      Events.list_queued_events_for_topic(
        batch_size: batch_size,
        destination: destination
      )

    # lock the events
    Events.lock_destination_events(destination.id, events)

    {:reply, events, state}
  end

  # We are unlocking events through to queued events genserver to force the calls to be queued to allow use to properly update the destination locks.  
  def handle_call(
        {:unlocked_queued_events, event_ids},
        _from,
        %{"destination" => destination} =
          state
      ) do
    event_ids = Enum.join(event_ids, ", ")
    # get the events
    events =
      Events.list_events_for_topic(
        destination.topic_name,
        offset: 0,
        batch_size: 100_000,
        topic_identifier: destination.topic_identifier,
        predicates: "id in [#{event_ids}]",
        include_all: true
      )

    # unlock the events
    Events.unlock_destination_events(destination.id, events.results)

    {:reply, events.results, state}
  end

  def handle_terminate(reason, state) do
    Logger.debug("Queued Events server terminated: #{inspect(reason)}")
    Logger.debug("Queued Events server state: #{inspect(state)}")
    :ok
  end

  @spec name(binary()) :: binary()
  def name(id) do
    "queued_events:" <> id
  end
end
