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
  def encode(t, messages, destination, opts \\ [])

  @doc """
  File extension for the format
  """
  @spec extension(term()) :: binary()
  def extension(t)
end

defimpl ER.Destinations.File.Format, for: Any do
  alias ER.Events.Event
  alias ER.Transformers.Transformer

  def encode(encoder, messages, destination, _opts) do
    messages
    |> Enum.map(fn message ->
      event =
        message.data

      event
      |> Event.to_map()
      |> Transformer.transform(destination)
      |> Map.put_new(:id, event.id)
    end)
    |> Jason.encode!()
    |> then(fn encoded ->
      {encoder, encoded}
    end)
  end

  def extension(_encoder) do
    "json"
  end
end
