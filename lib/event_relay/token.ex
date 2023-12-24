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
  require Logger
  use Joken.Config
  alias ER.Repo
  alias ER.Accounts.ApiKey
  @behaviour ER.JWT.TokenAdapter

  @impl true
  def build(api_key, claims \\ %{}) do
    claims =
      claims
      |> merge_api_key_claims(api_key)
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

  def merge_api_key_claims(claims, %ApiKey{type: :consumer} = api_key) do
    destination_ids = Repo.preload(api_key, :destinations).destinations |> Enum.map(& &1.id)
    Map.merge(claims, %{sub_ids: destination_ids}) |> merge_default_api_key_claims(api_key)
  end

  def merge_api_key_claims(claims, %ApiKey{type: :producer} = api_key) do
    topic_names = Repo.preload(api_key, :topics).topics |> Enum.map(& &1.name)
    Map.merge(claims, %{topic_names: topic_names}) |> merge_default_api_key_claims(api_key)
  end

  def merge_api_key_claims(claims, %ApiKey{type: :admin} = api_key) do
    Map.merge(claims, %{api_key_id: api_key.id}) |> merge_default_api_key_claims(api_key)
  end

  def merge_default_api_key_claims(claims, %ApiKey{id: id, type: type}) do
    Map.merge(claims, %{api_key_id: id, api_key_type: type})
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
