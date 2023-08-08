defmodule ERWeb.ApiKeyLive.Show do
  use ERWeb, :live_view

  alias ER.Accounts
  alias ER.Repo

  @impl true
  def mount(_params, _session, socket) do
    topics = ER.Events.list_topics()
    socket = socket |> assign(:topics, topics)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    api_key =
      Accounts.get_api_key!(id)
      |> Repo.preload(:topics)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:api_key, api_key)}
  end

  defp page_title(:show), do: "Show API key"
  defp page_title(:edit), do: "Edit API key"
end
