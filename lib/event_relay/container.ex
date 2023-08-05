defmodule ER.Container do
  def channel_cache() do
    Application.get_env(:event_relay, :channel_cache, ER.Events.ChannelCache)
  end

  def channel_monitor() do
    Application.get_env(:event_relay, :channel_monitor, ER.ChannelMonitor)
  end

  def s3() do
    Application.get_env(:event_relay, :s3, ER.S3)
  end
end
