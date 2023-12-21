defmodule ERWeb.PrunerLive.Show do
  use ERWeb, :live_view

  alias ER.Pruners

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:topics, ER.Events.list_topics())

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:pruner, Pruners.get_pruner!(id))}
  end

  defp page_title(:show), do: "Show Pruner"
  defp page_title(:edit), do: "Edit Pruner"
end
