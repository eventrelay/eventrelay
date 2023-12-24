defmodule ER.Destinations.Push.Factory do
  alias ER.Destinations.Push.{
    TopicDestination,
    S3Destination,
    WebhookDestination,
    WebsocketDestination,
    NoopDestination
  }

  def build(%{destination_type: :topic} = destination) do
    %TopicDestination{destination: destination}
  end

  def build(%{destination_type: :s3} = destination) do
    %S3Destination{destination: destination}
  end

  def build(%{destination_type: :webhook} = destination) do
    %WebhookDestination{destination: destination}
  end

  def build(%{destination_type: :websocket} = destination) do
    %WebsocketDestination{destination: destination}
  end

  def build(destination) do
    %NoopDestination{destination: destination}
  end
end
