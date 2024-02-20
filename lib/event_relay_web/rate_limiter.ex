defmodule ERWeb.RateLimiter do
  def check_rate(type, context \\ []) do
    if ER.Env.use_redis?() do
      check_rate_redis(type, context)
    else
      check_rate_ets(type, context)
    end
  end

  defp rate(type, context) do
    # TODO make this configurable via ENV
    case {type, context} do
      {"publish_events", [durable: false]} ->
        {"request:publish_events:ephemeral", 1_000, 50_000}

      {"publish_events", [durable: true]} ->
        {"request:publish_events:durable", 1_000, 50_000}

      {"create_topic", _context} ->
        {"request:create_topic", 1_000, 5}

      _ ->
        {"request:#{type}", 1_000, 10_000}
    end
  end

  defp check_rate_redis(type, context) do
    {key, time_frame, max_req} = rate(type, context)

    case Hammer.check_rate(:redis, key, time_frame, max_req) do
      {:allow, count} ->
        {:allow, count}

      {:deny, _} ->
        {:deny, type, time_frame, max_req}
    end
  end

  defp check_rate_ets(type, context) do
    {key, time_frame, max_req} = rate(type, context)

    case Hammer.check_rate(:ets, key, time_frame, max_req) do
      {:allow, count} ->
        {:allow, count}

      {:deny, _} ->
        {:deny, type, time_frame, max_req}
    end
  end
end
