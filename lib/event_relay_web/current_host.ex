defmodule ERWeb.CurrentHost do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    current_host =
      ["#{conn.scheme}://#{conn.host}", Flamel.to_string(conn.port)]
      |> Enum.join(":")
      |> URI.parse()

    conn
    |> put_session(:current_host, current_host)
  end

  def on_mount(:ensure_host, _params, session, socket) do
    socket =
      socket
      |> Phoenix.Component.assign(:current_host, Map.get(session, "current_host"))

    {:cont, socket}
  end
end
