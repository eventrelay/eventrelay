defmodule ER.Destinations.Server do
  @moduledoc """
  Manages the destinations
  """
  require Logger
  use GenServer
  use ER.Server
  alias Phoenix.PubSub
  alias ER.Destinations.Destination
  alias ER.Destinations.Push.Destination, as: Pusher

  def handle_continue(:load_state, %{"id" => id} = state) do
    destination = ER.Destinations.get_destination!(id)
    topic_name = destination.topic_name
    topic_identifier = destination.topic_identifier
    full_topic = ER.Events.Topic.build_topic(topic_name, topic_identifier)

    state =
      state
      |> Map.put(:topic_name, topic_name)
      |> Map.put(:topic_identifier, topic_identifier)
      |> Map.put(:full_topic, full_topic)
      |> Map.put(:destination, destination)

    Logger.debug("Destinations server started for #{inspect(full_topic)}")
    PubSub.subscribe(ER.PubSub, full_topic)

    schedule_next_tick()
    {:noreply, state}
  end

  def handle_info(
        {:event_created, event},
        %{destination: destination} = state
      ) do
    Logger.debug(
      "#{__MODULE__}.handle_info({:event_created, #{inspect(event)}}, #{inspect(state)}) on node=#{inspect(Node.self())}"
    )

    # find metrics for the topic and create events for the metric update
    topic_name = event.topic_name
    topic_identifier = event.topic_identifier

    events =
      ER.Metrics.build_metric_updates(
        topic_name: topic_name,
        topic_identifier: topic_identifier
      )
      |> ER.Metrics.publish_metric_updates()
      |> Enum.map(&elem(&1, 1))

    events =
      if handle_event?(destination, event) do
        [event | events]
      else
        Logger.debug(
          "#{__MODULE__}.handle_info({:event_created, #{inspect(event)}} not handling event #{inspect(state)}) on node=#{inspect(Node.self())}"
        )

        events
      end

    push_destination = ER.Destinations.Push.Factory.build(destination)
    Enum.map(events, &Pusher.push(push_destination, &1))

    {:noreply, state}
  end

  def handle_info(:tick, state) do
    # Logger.debug("#{__MODULE__}.handle_info(:tick)")
    schedule_next_tick()
    {:noreply, state}
  end

  def handle_event?(destination, event) do
    Destination.matches?(destination, event)
  end

  def handle_terminate(reason, state) do
    Logger.debug("Destination server terminated: #{inspect(reason)}")
    Logger.debug("Destination server state: #{inspect(state)}")
    # TODO: save state to redis if needed or delete it if this is a good termination
  end

  @spec tick_interval() :: integer()
  def tick_interval(tick_interval \\ nil) do
    tick_interval ||
      ER.to_integer(System.get_env("ER_SUBSCRIPTION_SERVER_TICK_INTERVAL") || "5000")
  end

  @spec name(binary()) :: binary()
  def name(id) do
    "destination:" <> id
  end
end
