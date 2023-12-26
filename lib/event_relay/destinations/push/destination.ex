defprotocol ER.Destinations.Push.Destination do
  alias ER.Events.Event

  @spec push(t, %Event{}) :: term()
  def push(destination, event)
end
