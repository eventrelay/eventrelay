defmodule ER.Events.ChannelCache do
  use Nebulex.Cache,
    otp_app: :event_relay,
    adapter: Nebulex.Adapters.Horde,
    horde: [
      members: :auto,
      process_redistribution: :passive
      # any other Horde options ...
    ]

  require Logger

  def register_socket(pid, destination_id, monitor_channel \\ true) do
    Logger.debug("Registering socket #{inspect(pid)} for destination #{inspect(destination_id)}")

    if monitor_channel do
      :ok =
        ER.ChannelMonitor.monitor(
          :events,
          pid,
          {__MODULE__, :deregister_socket, [destination_id]}
        )
    end

    incr(destination_id)
  end

  def deregister_socket(destination_id) do
    Logger.debug("Deregistering socket for destination #{destination_id}")
    decr(destination_id)
  end

  def get_socket_count(destination_id) do
    get(destination_id) |> ER.to_integer()
  end

  def any_sockets?(destination_id) do
    get_socket_count(destination_id) > 0
  end
end
