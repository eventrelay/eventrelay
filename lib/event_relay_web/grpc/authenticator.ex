defmodule ERWeb.Grpc.EventRelay.Interceptors.Authenticator do
  @moduledoc """
  """

  require Logger
  alias ER.Accounts
  alias ER.Accounts.ApiKey

  # @behaviour GRPC.Server.Interceptor
  #
  # @impl GRPC.Server.Interceptor
  def init(opts) do
    opts
  end

  # @impl GRPC.Server.Interceptor
  def call(req, stream, next, _opts) do
    if ER.Env.skip_grpc_auth?() do
      Logger.debug("Skipping GRPC auth--------------------------")
      next.(req, stream)
    else
      headers = GRPC.Stream.get_headers(stream)
      bearer_token = headers["authorization"]
      authenticate(bearer_token, req, stream, next)
    end
  end

  defp authenticate("Bearer " <> token, req, stream, next) do
    token
    |> ApiKey.decode_key_and_secret()
    |> validate_api_key(req, stream, next)
  end

  defp authenticate(_token, _req, _stream, _next) do
    raise GRPC.RPCError,
      status: GRPC.Status.unauthenticated(),
      message: "Invalid credentials: could not find bearer token"
  end

  defp validate_api_key({:ok, key, secret}, req, stream, next) do
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
  end

  defp validate_api_key({:error, _}, _req, _stream, _next) do
    raise GRPC.RPCError,
      status: GRPC.Status.unauthenticated(),
      message: "Invalid credentials: could not decode bearer token"
  end
end
