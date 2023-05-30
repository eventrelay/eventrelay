defmodule ERWeb.RateLimiter do
  def check_rate(type, context \\ []) do
    {key, time_frame, max_req} = rate(type, context)

    case Hammer.check_rate(key, time_frame, max_req) do
      {:allow, count} -> {:allow, count}
      {:deny, _} -> {:deny, type, time_frame, max_req}
    end
  end

  defp rate(type, context) do
    # TODO make this configurable via ENV
    case {type, context} do
      {"publish_events", [durable: false]} ->
        {"request:publish_events:ephemeral", 1_000, 20_000}

      {"publish_events", [durable: true]} ->
        {"request:publish_events:durable", 1_000, 10_000}

      {"create_topic", _context} ->
        {"request:create_topic", 1_000, 5}

      _ ->
        {"request:#{type}", 1_000, 20}
    end
  end
end
