defprotocol ER.Destinations.File do
  @moduledoc """
  The `ER.Destinations.File` puts events in a file in some 
  destination.
  """

  alias Broadway.Message

  @fallback_to_any true

  @doc """
  Put files in the destination
  """
  @spec put(term(), [Message.t()], Keyword.t()) :: [Message.t()]
  def put(t, messages, opts \\ [])
end

defimpl ER.Destinations.File, for: Any do
  def put(_service, messages, _opts) do
    messages
  end
end
