defmodule ER.Subscriptions.Server do
  @moduledoc """
  Manages the subscriptions
  """
  require Logger
  use GenServer
  use ER.Server
  alias Phoenix.PubSub
  alias ER.Subscriptions.Subscription

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

    Logger.debug("Subscriptions server started for #{inspect(full_topic)}")
    PubSub.subscribe(ER.PubSub, full_topic)

    schedule_next_tick()
    {:noreply, state}
  end

  def handle_info(
        {:event_created, event},
        %{subscription: subscription} = state
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
      if handle_event?(subscription, event) do
        [event | events]
      else
        Logger.debug(
          "#{__MODULE__}.handle_info({:event_created, #{inspect(event)}} not handling event #{inspect(state)}) on node=#{inspect(Node.self())}"
        )

        events
      end

    cond do
      Subscription.push_to_websocket?(subscription) ->
        Enum.map(events, &ER.Subscriptions.Delivery.Websocket.push(subscription, &1))

      Subscription.push_to_webhook?(subscription) ->
        # TODO implement a queue and rate limiting
        Enum.map(events, &ER.Subscriptions.Delivery.Webhook.push(subscription, &1))

      Subscription.push_to_s3?(subscription) ->
        Enum.map(events, &ER.Subscriptions.Delivery.S3.push(subscription, &1))

      Subscription.push_to_topic?(subscription) ->
        Enum.map(events, &ER.Subscriptions.Delivery.Topic.push(subscription, &1))

      true ->
        Logger.debug("Not pushing event=#{inspect(event)} subscription=#{inspect(subscription)}")
    end

    {:noreply, state}
  end

  def handle_info(:tick, state) do
    # Logger.debug("#{__MODULE__}.handle_info(:tick)")
    schedule_next_tick()
    {:noreply, state}
  end

  def handle_event?(subscription, event) do
    Subscription.matches?(subscription, event)
  end

  def handle_terminate(reason, state) do
    Logger.debug("Subscription server terminated: #{inspect(reason)}")
    Logger.debug("Subscription server state: #{inspect(state)}")
    # TODO: save state to redis if needed or delete it if this is a good termination
  end

  @spec tick_interval() :: integer()
  def tick_interval(tick_interval \\ nil) do
    tick_interval ||
      ER.to_integer(System.get_env("ER_SUBSCRIPTION_SERVER_TICK_INTERVAL") || "5000")
  end

  @spec name(binary()) :: binary()
  def name(id) do
    "subscription:" <> id
  end
end
