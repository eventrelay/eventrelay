defmodule ER.Events.ChannelCacheBehavior do
  @callback register_socket(pid(), binary()) :: integer()
  @callback deregister_socket(binary()) :: integer()
  @callback get_socket_count(binary()) :: integer()
  @callback any_sockets?(binary()) :: boolean()
end

defmodule ER.Events.ChannelCache do
  use Nebulex.Cache,
    otp_app: :event_relay,
    adapter: Nebulex.Adapters.Horde,
    horde: [
      members: :auto,
      process_redistribution: :passive
      # any other Horde options ...
    ]

  @behaviour ER.Events.ChannelCacheBehavior

  require Logger

  @impl true
  def register_socket(pid, subscription_id, monitor_channel \\ true) do
    Logger.debug(
      "Registering socket #{inspect(pid)} for subscription #{inspect(subscription_id)}"
    )

    if monitor_channel do
      :ok =
        ER.ChannelMonitor.monitor(
          :events,
          pid,
          {__MODULE__, :deregister_socket, [subscription_id]}
        )
    end

    incr(subscription_id)
  end

  @impl true
  def deregister_socket(subscription_id) do
    Logger.debug("Deregistering socket for subscription #{subscription_id}")
    decr(subscription_id)
  end

  @impl true
  def get_socket_count(subscription_id) do
    get(subscription_id) |> ER.to_integer()
  end

  @impl true
  def any_sockets?(subscription_id) do
    get_socket_count(subscription_id) > 0
  end
end
