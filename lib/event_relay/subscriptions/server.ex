defmodule ER.Subscriptions.Server do
  @moduledoc """
  Manages the subscriptions
  """
  require Logger
  use GenServer
  use ER.Server
  alias Phoenix.PubSub

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

    cond do
      broadcast_to_websocket?(subscription) ->
        ER.Subscriptions.Delivery.Websocket.push(subscription, event)

      push_to_webhook?(subscription) ->
        ER.Subscriptions.Delivery.Webhook.push(subscription, event)

      true ->
        Logger.debug("Not pushing event=#{inspect(event)}")
    end

    {:noreply, state}
  end

  def broadcast_to_websocket?(subscription) do
    subscription.push && subscription.subscription_type == "websocket" &&
      ER.Events.ChannelCache.any_sockets?(subscription.id)
  end

  def push_to_webhook?(subscription) do
    subscription.push && subscription.subscription_type == "webhook"
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
