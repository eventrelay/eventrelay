defprotocol ER.Destinations.Database do
  @moduledoc """
  The `ER.Destinations.Database` inserts events to a destination database.
  """

  alias Broadway.Message

  @fallback_to_any true

  @doc """
  Inserts events to a database
  """
  @spec insert(term(), [Message.t()]) :: [Message.t()]
  def insert(t, messages)

  @doc """
  Prepares any processes it needs to handles events 
  """
  @spec prepare_for_start(term()) :: term()
  def prepare_for_start(t)
end

defimpl ER.Destinations.Database, for: Any do
  require Logger

  def prepare_for_start(database) do
    Logger.error(
      "#{__MODULE__}.prepare_for_start not implemented for database=#{inspect(database)}"
    )

    database
  end

  def insert(database, _messages) do
    Logger.error("#{__MODULE__}.insert not implemented for database=#{inspect(database)}")
    raise RuntimeError
  end
end
