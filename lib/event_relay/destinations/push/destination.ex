defprotocol ER.Destinations.Push.Destination do
  def push(destination, event)
end

defimpl ER.Destinations.Push.Destination, for: Any do
  require Logger

  def push(destination, event) do
    Logger.debug("Not pushing event=#{inspect(event)} destination=#{inspect(destination)}")
  end
end
