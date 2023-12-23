defprotocol ER.Subscriptions.Push.Subscription do
  def push(subscription, event)
end

defimpl ER.Subscriptions.Push.Subscription, for: Any do
  require Logger

  def push(subscription, event) do
    Logger.debug("Not pushing event=#{inspect(event)} subscription=#{inspect(subscription)}")
  end
end
