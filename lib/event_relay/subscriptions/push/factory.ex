defmodule ER.Subscriptions.Push.Factory do
  alias ER.Subscriptions.Push.{
    TopicSubscription,
    S3Subscription,
    WebhookSubscription,
    WebsocketSubscription
  }

  def build(%{subscription_type: :topic} = subscription) do
    %TopicSubscription{subscription: subscription}
  end

  def build(%{subscription_type: :s3} = subscription) do
    %S3Subscription{subscription: subscription}
  end

  def build(%{subscription_type: :webhook} = subscription) do
    %WebhookSubscription{subscription: subscription}
  end

  def build(%{subscription_type: :websocket} = subscription) do
    %WebsocketSubscription{subscription: subscription}
  end
end
