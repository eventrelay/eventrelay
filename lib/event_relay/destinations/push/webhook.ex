defmodule ER.Destinations.Push.WebhookDestination do
  defstruct destination: nil
end

defimpl ER.Destinations.Push.Destination, for: ER.Destinations.Push.WebhookDestination do
  require Logger
  alias ER.Events.Event
  alias ER.Destinations.Push.WebhookDestination

  def push(%WebhookDestination{destination: %{paused: false} = destination}, %Event{} = event) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(destination)}, #{inspect(event)}) on node=#{inspect(Node.self())}"
    )

    topic_name = destination.topic_name

    delivery = ER.Destinations.build_delivery_for_topic(topic_name)
    Logger.debug("Created delivery #{inspect(delivery)}")

    ER.Destinations.Webhook.Delivery.Server.factory(delivery.id, %{
      "topic_name" => topic_name,
      "delivery" => delivery,
      "destination" => destination,
      "event" => event
    })
  end

  def push(%WebhookDestination{destination: destination}, %Event{} = event) do
    Logger.debug(
      "#{__MODULE__}.push(#{inspect(destination)}, #{inspect(event)}) do not push on node=#{inspect(Node.self())}"
    )
  end
end
