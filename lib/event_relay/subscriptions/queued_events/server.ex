defmodule ER.Subscriptions.QueuedEvents.Server do
  @moduledoc """
  Manages the pull and unlocking queued events
  """
  require Logger
  use GenServer
  use ER.Server
  alias ER.Events

  def handle_continue(:load_state, %{"id" => id} = state) do
    subscription = ER.Subscriptions.get_subscription!(id)
    topic_name = subscription.topic_name
    topic_identifier = subscription.topic_identifier
    full_topic = ER.Events.Topic.build_topic(topic_name, topic_identifier)

    state =
      state
      |> Map.put(:topic_name, topic_name)
      |> Map.put(:topic_identifier, topic_identifier)
      |> Map.put(:full_topic, full_topic)
      |> Map.put(:subscription, subscription)

    Logger.debug("Queued Events server started for #{inspect(full_topic)}")

    {:noreply, state}
  end

  def pull_queued_events(args) do
    GenServer.call(via(args[:subscription_id]), {:pull_queued_events, args[:batch_size]})
  end

  def unlocked_queued_events(args) do
    GenServer.call(
      via(args[:subscription_id]),
      {:unlocked_queued_events, args[:event_ids]}
    )
  end

  # We are retrieving events through to subscription genserver to force the calls to be queued to allow use to properly update the subscription locks to enforce a deliver once constraint via the API.  
  def handle_call(
        {:pull_queued_events, batch_size},
        _from,
        %{"id" => subscription_id, topic_name: topic_name, topic_identifier: topic_identifier} =
          state
      ) do
    # get the events
    events =
      Events.list_queued_events_for_topic(
        batch_size: batch_size,
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        subscription_id: subscription_id
      )

    # lock the events
    Events.lock_subscription_events(subscription_id, events)

    {:reply, events, state}
  end

  # We are unlocking events through to subscription genserver to force the calls to be queued to allow use to properly update the subscription locks.  
  def handle_call(
        {:unlocked_queued_events, event_ids},
        _from,
        %{"id" => subscription_id, topic_name: topic_name, topic_identifier: topic_identifier} =
          state
      ) do
    event_ids = Enum.join(event_ids, ", ")
    # get the events
    events =
      Events.list_events_for_topic(
        offset: 0,
        batch_size: 100,
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        query: "id in [#{event_ids}]"
      )

    # lock the events
    Events.unlock_subscription_events(subscription_id, events.results)

    {:reply, events.results, state}
  end

  def handle_terminate(reason, state) do
    Logger.debug("Queued Events server terminated: #{inspect(reason)}")
    Logger.debug("Queued Events server state: #{inspect(state)}")
  end

  @spec name(binary()) :: binary()
  def name(id) do
    "queued_events:" <> id
  end
end
