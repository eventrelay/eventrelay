defmodule ER.Container do
  def channel_cache() do
    Application.get_env(:event_relay, :channel_cache)
  end
end
