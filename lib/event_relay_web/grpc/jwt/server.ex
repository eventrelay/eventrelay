defmodule ERWeb.Grpc.EventRelay.JWT.Server do
  @moduledoc """
  GRPC Server implementation for JWT Service
  """
  use GRPC.Server, service: ERWeb.Grpc.Eventrelay.JWT.Service
  require Logger

  alias ERWeb.Grpc.Eventrelay.{
    CreateJWTRequest,
    CreateJWTResponse
  }

  @spec create_jwt(CreateJWTRequest.t(), GRPC.Server.Stream.t()) :: CreateJWTResponse.t()
  def create_jwt(request, _stream) do
    claims =
      if ER.empty?(request.expiration) do
        %{}
      else
        %{
          exp: request.expiration
        }
      end

    case ER.JWT.Token.build(request.api_key, claims) do
      {:ok, jwt} ->
        CreateJWTResponse.new(jwt: jwt)

      {:error, _reason} ->
        raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
    end
  end
end
