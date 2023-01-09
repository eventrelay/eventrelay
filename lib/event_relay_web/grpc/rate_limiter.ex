defmodule ERWeb.Grpc.EventRelay.Interceptors.RateLimiter do
  @moduledoc """
  """

  require Logger

  @behaviour GRPC.Server.Interceptor

  @impl GRPC.Server.Interceptor
  def init(opts) do
    opts
  end

  @impl GRPC.Server.Interceptor
  def call(req, stream, next, opts) do
    rpc_method = stream.rpc |> elem(0) |> to_string()
    {time_frame, max_req} = rate(rpc_method)

    case Hammer.check_rate("grpc:request:#{rpc_method}", time_frame, max_req) do
      {:allow, _count} ->
        next.(req, stream)

      {:deny, _limit} ->
        message =
          "Rate limit exceeded for #{rpc_method} at #{max_req} requests per #{time_frame / 1000} second(s)"

        raise GRPC.RPCError,
          status: GRPC.Status.resource_exhausted(),
          message: message
    end
  end

  defp rate(rpc_method) do
    # TODO make this configurable via ENV
    case rpc_method do
      "publish_events" ->
        {1_000, 200}

      _ ->
        {1_000, 5}
    end
  end
end
