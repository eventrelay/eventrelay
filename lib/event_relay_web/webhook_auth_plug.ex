defmodule ERWeb.WebhookAuth do
  @moduledoc """
  A plug that checks basic auth for an inbound webhook request
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> get_key_and_secret()
    |> verify_key_and_secret(conn)
    |> case do
      {:ok, ingestor} -> assign(conn, :ingestor, ingestor)
      _unauthorized -> assign(conn, :ingestor, nil)
    end
  end

  def authenticate_webhook_request(conn, _opts) do
    if Map.get(conn.assigns, :ingestor) do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> put_view(ERWeb.ErrorJSON)
      |> render(:"401")
      |> halt()
    end
  end

  def verify_key_and_secret({key, secret}, conn) do
    try do
      ingestor_id = conn.params["ingestor_id"]
      ingestor = ER.Ingestors.get_ingestor!(ingestor_id)

      if ingestor.key == key && ingestor.secret == secret do
        {:ok, ingestor}
      else
        nil
      end
    rescue
      _ ->
        nil
    end
  end

  def verify_key_and_secret(_key_and_secret, _conn) do
    nil
  end

  @spec get_key_and_secret(Plug.Conn.t()) :: nil | binary
  def get_key_and_secret(conn) do
    with ["Basic " <> encoded_user_and_pass] <- get_req_header(conn, "authorization"),
         {:ok, decoded_user_and_pass} <- Base.decode64(encoded_user_and_pass),
         [user, pass] <- :binary.split(decoded_user_and_pass, ":") do
      {user, pass}
    else
      _ -> nil
    end
  end
end
