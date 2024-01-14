defprotocol ER.Destinations.File.Format do
  @moduledoc """
  The `ER.Destinations.File.Format` encodes events in a format.
  """

  alias Broadway.Message

  @fallback_to_any true

  @doc """
  Encode the events
  """
  @spec encode(term(), [Message.t()], Keyword.t()) :: {term(), term()}
  def encode(t, messages, opts \\ [])

  @doc """
  File extension for the format
  """
  @spec extension(term()) :: binary()
  def extension(t)
end

defimpl ER.Destinations.File.Format, for: Any do
  def encode(encoder, messages, _opts) do
    messages
    |> Enum.map(& &1.data)
    |> Jason.encode!()
    |> then(fn encoded ->
      {encoder, encoded}
    end)
  end

  def extension(_encoder) do
    "json"
  end
end
