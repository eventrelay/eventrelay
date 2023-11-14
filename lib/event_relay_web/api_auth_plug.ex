defmodule ERWeb.APIAuth do
  @moduledoc """
  A module plug that verifies the bearer token in the request headers. The authorization header value may look like
  `Bearer xxxxxxx`.
  """

  import Plug.Conn
  import Phoenix.Controller
  alias ER.Accounts.ApiKey
  alias ER.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> get_token()
    |> verify_token()
    |> case do
      {:ok, api_key} -> assign(conn, :api_key, api_key)
      _unauthorized -> assign(conn, :api_key, nil)
    end
  end

  def authenticate_api_token(conn, _opts) do
    if Map.get(conn.assigns, :api_key) do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> put_view(ERWeb.ErrorJSON)
      |> render(:"401")
      |> halt()
    end
  end

  def verify_token(token) do
    case ApiKey.decode_key_and_secret(token) do
      {:ok, key, secret} ->
        case Accounts.get_active_api_key_by_key_and_secret(key, secret) do
          nil ->
            {:error, "Not a valid token"}

          api_key ->
            {:ok, api_key}
        end

      {:error, message} ->
        {:error, message}
    end
  end

  @spec get_token(Plug.Conn.t()) :: nil | binary
  def get_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end
end
