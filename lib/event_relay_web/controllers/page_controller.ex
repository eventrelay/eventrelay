defmodule ERWeb.PageController do
  use ERWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/topics")
  end
end
