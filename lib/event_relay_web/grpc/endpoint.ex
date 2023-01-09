defmodule ERWeb.Grpc.Endpoint do
  use GRPC.Endpoint

  intercept(GRPC.Logger.Server, level: :debug)
  intercept(ERWeb.Grpc.EventRelay.Interceptors.RateLimiter)
  intercept(ERWeb.Grpc.EventRelay.Interceptors.Authenticator)
  run(ERWeb.Grpc.EventRelay.Server)
end
