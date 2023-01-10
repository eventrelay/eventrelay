defmodule ERWeb.RateLimiter do
  def check_rate(method) do
    {time_frame, max_req} = rate(method)

    case Hammer.check_rate("request:#{method}", time_frame, max_req) do
      {:allow, count} -> {:allow, count}
      {:deny, _} -> {:deny, method, time_frame, max_req}
    end
  end

  defp rate(method) do
    # TODO make this configurable via ENV
    case method do
      "publish_events" ->
        {1_000, 200}

      _ ->
        {1_000, 5}
    end
  end
end
