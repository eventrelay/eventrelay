defmodule ER.JWT.TokenAdapter do
  @moduledoc """
  Adapter for the JWT Token
  """
  @callback user_token(user :: User.t()) :: binary()
end

defmodule ER.JWT.Token do
  @moduledoc """
  JWT tokens 

  User Tokens


  """
  use Joken.Config
  alias ER.Repo
  @behaviour ER.JWT.TokenAdapter

  @impl ELWeb.JWT.TokenAdapter
  def user_token(user, claims \\ %{}) do
    user = Repo.preload(user, team_users: [role: [:permissions]])

    teams =
      Enum.reduce(user.team_users, %{}, fn team_user, acc ->
        Map.put(
          acc,
          EL.to_string(team_user.team_id),
          Enum.map(team_user.role.permissions, fn permission -> permission.name end)
        )
      end)

    claims = Map.merge(claims, %{user_id: user.id, teams: teams, exp: user_token_exp()})

    {:ok, token, _claims} =
      encode_and_sign(
        claims,
        signer()
      )

    token
  end

  defp user_token_exp() do
    DateTime.now!("Etc/UTC") |> DateTime.add(2_592_000) |> DateTime.to_unix()
  end

  @spec signer :: Joken.Signer.t()
  def signer do
    key = Application.get_env(:everylink, ELWeb.Endpoint)[:secret_key_base]
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
