defmodule ER.JWT.TokenAdapter do
  @moduledoc """
  Adapter for the JWT Token
  """
  alias ER.Accounts.ApiKey
  @callback build(api_key :: ApiKey.t(), claims :: map()) :: {:ok, binary()} | {:error, any()}
end

defmodule ER.JWT.Token do
  @moduledoc """
  JWT tokens 
  """
  use Joken.Config
  alias ER.Repo
  @behaviour ER.JWT.TokenAdapter

  @impl true
  def build(api_key, claims \\ %{}) do
    claims =
      claims
      |> Map.merge(%{api_key_id: api_key.id, subscriptions: []})
      |> ensure_exp()

    case encode_and_sign(
           claims,
           signer()
         ) do
      {:ok, token, _claims} ->
        {:ok, token}

      {:error, reason} ->
        Logger.error("Error building token: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp ensure_exp(%{exp: exp} = claims) when is_nil(exp) do
    # 1 hour exp default
    exp = DateTime.now!("Etc/UTC") |> DateTime.add(3_600_000) |> DateTime.to_unix()
    Map.merge(claims, %{exp: exp})
  end

  defp ensure_exp(claims) do
    claims
  end

  @spec signer :: Joken.Signer.t()
  def signer do
    key = Application.get_env(:event_relay, ERWeb.Endpoint)[:secret_key_base]
    Joken.Signer.create("HS256", key)
  end

  @spec get_claims(binary) :: {:error, atom | keyword} | {:ok, %{optional(binary) => any}}
  def get_claims(token) do
    verify_and_validate(
      token,
      signer()
    )
  end
end
