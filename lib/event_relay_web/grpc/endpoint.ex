defmodule ERWeb.Grpc.Endpoint do
  @moduledoc """
  This module is where all the GRPC servers that implement the services are
  configured.
  """
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

  run(ERWeb.Grpc.EventRelay.Destinations.Server,
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
