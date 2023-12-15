defmodule ERWeb.Grpc.Endpoint do
  use GRPC.Endpoint

  run(ERWeb.Grpc.EventRelay.Events.Server,
    interceptors: [
      GRPC.Server.Interceptors.Logger,
      ERWeb.Grpc.EventRelay.Interceptors.RateLimiter,
      ERWeb.Grpc.EventRelay.Interceptors.Authenticator
    ]
  )

  run(ERWeb.Grpc.EventRelay.Topics.Server,
    interceptors: [
      GRPC.Server.Interceptors.Logger,
      ERWeb.Grpc.EventRelay.Interceptors.RateLimiter,
      ERWeb.Grpc.EventRelay.Interceptors.Authenticator
    ]
  )

  run(ERWeb.Grpc.EventRelay.Subscriptions.Server,
    interceptors: [
      GRPC.Server.Interceptors.Logger,
      ERWeb.Grpc.EventRelay.Interceptors.RateLimiter,
      ERWeb.Grpc.EventRelay.Interceptors.Authenticator
    ]
  )

  run(ERWeb.Grpc.EventRelay.Metrics.Server,
    interceptors: [
      GRPC.Server.Interceptors.Logger,
      ERWeb.Grpc.EventRelay.Interceptors.RateLimiter,
      ERWeb.Grpc.EventRelay.Interceptors.Authenticator
    ]
  )

  run(ERWeb.Grpc.EventRelay.ApiKeys.Server,
    interceptors: [
      GRPC.Server.Interceptors.Logger,
      ERWeb.Grpc.EventRelay.Interceptors.RateLimiter,
      ERWeb.Grpc.EventRelay.Interceptors.Authenticator
    ]
  )

  run(ERWeb.Grpc.EventRelay.JWT.Server,
    interceptors: [
      GRPC.Server.Interceptors.Logger,
      ERWeb.Grpc.EventRelay.Interceptors.RateLimiter,
      ERWeb.Grpc.EventRelay.Interceptors.Authenticator
    ]
  )
end
