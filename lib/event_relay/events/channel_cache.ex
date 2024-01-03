defmodule ER.Events.ChannelCacheBehavior do
  @callback register_socket(pid(), binary()) :: integer()
  @callback deregister_socket(binary()) :: integer()
  @callback get_socket_count(binary()) :: integer()
  @callback any_sockets?(binary()) :: boolean()
end

defmodule ER.Events.ChannelCache do
  use Nebulex.Cache,
    otp_app: :event_relay,
    adapter: Nebulex.Adapters.Local

  @behaviour ER.Events.ChannelCacheBehavior

  require Logger

  @impl true
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

  @impl true
  def deregister_socket(destination_id) do
    Logger.debug("Deregistering socket for destination #{destination_id}")
    decr(destination_id)
  end

  @impl true
  def get_socket_count(destination_id) do
    get(destination_id) |> ER.to_integer()
  end

  @impl true
  def any_sockets?(destination_id) do
    get_socket_count(destination_id) > 0
  end
end
