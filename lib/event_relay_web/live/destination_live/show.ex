defmodule ERWeb.DestinationLive.Show do
  use ERWeb, :live_view

  alias ER.Destinations

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
     |> assign(:destination, Destinations.get_destination!(id))}
  end

  defp page_title(:show), do: "Show Destination"
  defp page_title(:edit), do: "Edit Destination"
end
