defmodule ER.Subscriptions.Delivery.Topic do
  require Logger
  alias ER.Subscriptions.Subscription
  alias ER.Events.Event

  @field_to_drop [:__meta__, :subscription_locks, :topic]

  def push(%Subscription{config: config} = subscription, %Event{} = event) do
    Logger.debug(
      "#{__MODULE__}.push_event(#{inspect(subscription)}, #{inspect(event)}) on node=#{inspect(Node.self())}"
    )

    topic_name = config["topic_name"]

    attrs = Map.from_struct(event)

    attrs =
      attrs
      |> Map.put(:topic_name, topic_name)
      |> Map.drop(@field_to_drop)

    ER.Events.produce_event_for_topic(attrs)
  end
end
