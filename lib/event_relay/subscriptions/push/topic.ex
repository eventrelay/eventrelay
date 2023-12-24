defmodule ER.Subscriptions.Push.TopicSubscription do
  defstruct subscription: nil
end

defimpl ER.Subscriptions.Push.Subscription, for: ER.Subscriptions.Push.TopicSubscription do
  require Logger
  alias ER.Events.Event
  alias ER.Subscriptions.Push.TopicSubscription

  @field_to_drop [:__meta__, :subscription_locks, :topic]

  def push(
        %TopicSubscription{subscription: %{paused: false, config: config} = subscription},
        %Event{} = event
      ) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(subscription)}, #{inspect(event)}) on node=#{inspect(Node.self())}"
    )

    topic_name = config["topic_name"]

    attrs = Map.from_struct(event)

    attrs =
      attrs
      |> Map.put(:topic_name, topic_name)
      |> Map.drop(@field_to_drop)

    ER.Events.produce_event_for_topic(attrs)
  end

  def push(%TopicSubscription{subscription: subscription}, %Event{} = event) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(subscription)}, #{inspect(event)}) do not push on node=#{inspect(Node.self())}"
    )
  end
end
