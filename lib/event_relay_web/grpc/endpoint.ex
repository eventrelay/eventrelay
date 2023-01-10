defmodule ERWeb.Grpc.Endpoint do
  use GRPC.Endpoint

  run(ERWeb.Grpc.EventRelay.Server,
    interceptors: [
      GRPC.Logger.Server,
      ERWeb.Grpc.EventRelay.Interceptors.RateLimiter,
      ERWeb.Grpc.EventRelay.Interceptors.Authenticator
    ]
  )
end
