defmodule ER.Subscriptions.Server do
  @moduledoc """
  Manages the subscriptions
  """
  require Logger
  use GenServer
  use ER.Server
  alias Phoenix.PubSub
  alias ER.Subscriptions.Subscription
  alias ER.Events

  def pull_queued_events(args) do
    GenServer.call(via(args[:subscription_id]), {:pull_queued_events, args[:batch_size]})
  end

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

  @doc """
  We are retrieving events through to subscription genserver to force the calls to be queued to allow use to properly update the subscription locks to enforce a deliver once constraint via the API.  
  """
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

    events = [event | events]

    cond do
      Subscription.push_to_websocket?(subscription) ->
        Enum.map(events, &ER.Subscriptions.Delivery.Websocket.push(subscription, &1))

      Subscription.push_to_webhook?(subscription) ->
        # TODO implement a queue and rate limiting
        Enum.map(events, &ER.Subscriptions.Delivery.Webhook.push(subscription, &1))

      Subscription.push_to_s3?(subscription) ->
        Enum.map(events, &ER.Subscriptions.Delivery.S3.push(subscription, &1))

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

  def handle_terminate(reason, state) do
    Logger.debug("Subscription server terminated: #{inspect(reason)}")
    Logger.debug("Subscription server state: #{inspect(state)}")
    # TODO: save state to redis if needed or delete it if this is a good termination
  end

  @spec name(binary()) :: binary()
  def name(id) do
    "subscription:" <> id
  end
end
