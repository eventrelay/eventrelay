defmodule ERWeb.Grpc.EventRelay.JWT.ServerTest do
  use ER.DataCase

  import ER.Factory
  alias ERWeb.Grpc.EventRelay.JWT.Server

  alias ERWeb.Grpc.Eventrelay.{
    CreateJWTRequest
  }

  describe "create_jwt/2" do
    test "create a new JWT for an API Key" do
      api_key =
        insert(:api_key)

      exp = DateTime.utc_now() |> DateTime.add(600, :second) |> DateTime.to_unix()

      request = %CreateJWTRequest{
        expiration: exp
      }

      request = Map.put(request, :api_key, api_key)

      result = Server.create_jwt(request, nil)

      refute result.jwt == nil

      {:ok, claims} = ER.JWT.Token.get_claims(result.jwt)

      assert claims["api_key_id"] == api_key.id
      assert claims["api_key_type"] == to_string(api_key.type)
      assert claims["exp"] == exp
    end
  end
end
