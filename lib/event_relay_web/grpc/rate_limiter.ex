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

    case ERWeb.RateLimiter.check_rate(rpc_method) do
      {:allow, _count} ->
        next.(req, stream)

      {:deny, method, time_frame, max_req} ->
        message =
          "Rate limit exceeded for #{method} at #{max_req} requests per #{time_frame / 1000} second(s)"

        raise GRPC.RPCError,
          status: GRPC.Status.resource_exhausted(),
          message: message
    end
  end
end
