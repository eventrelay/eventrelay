defmodule ERWeb.Grpc.EventRelay.Interceptors.Authenticator do
  @moduledoc """
  """

  require Logger
  alias ER.Accounts
  alias ER.Accounts.ApiKey

  @behaviour GRPC.Server.Interceptor

  @impl GRPC.Server.Interceptor
  def init(opts) do
    Logger.debug("ERWeb.Grpc.EventRelay.Interceptors.Auth.init(#{inspect(opts)})")
    opts
  end

  @impl GRPC.Server.Interceptor
  def call(req, stream, next, opts) do
    if ER.Env.skip_grpc_auth?() do
      next.(req, stream)
    else
      headers = GRPC.Stream.get_headers(stream)
      bearer_token = headers["authorization"]

      case bearer_token do
        "Bearer " <> token ->
          case ApiKey.decode_key_and_secret(token) do
            {:ok, key, secret} ->
              case Accounts.get_active_api_key_by_key_and_secret(key, secret) do
                nil ->
                  raise GRPC.RPCError,
                    status: GRPC.Status.unauthenticated(),
                    message: "Invalid credentials"

                api_key ->
                  case Bosun.permit(api_key, :request, req) do
                    {:ok, _} ->
                      req
                      |> Map.put(:api_key, api_key)
                      |> next.(stream)

                    {:error, context} ->
                      raise GRPC.RPCError,
                        status: GRPC.Status.permission_denied(),
                        message: context.reason
                  end
              end

            {:error, _} ->
              raise GRPC.RPCError,
                status: GRPC.Status.unauthenticated(),
                message: "Invalid credentials: could not decode bearer token"
          end

        _ ->
          raise GRPC.RPCError,
            status: GRPC.Status.unauthenticated(),
            message: "Invalid credentials: could not find bearer token"
      end
    end
  end
end
