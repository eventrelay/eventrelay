defmodule ERWeb.DestinationLive.Index do
  use ERWeb, :live_view

  alias ER.Destinations
  alias ER.Destinations.Destination

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:destinations, list_destinations())
      |> assign(:topics, ER.Events.list_topics())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Destination")
    |> assign(:destination, Destinations.get_destination!(id))
  end

  defp apply_action(socket, :edit_config, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Destination Config")
    |> assign(:destination, Destinations.get_destination!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Destination")
    |> assign(:destination, %Destination{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Destinations")
    |> assign(:destination, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    destination = Destinations.get_destination!(id)
    {:ok, _} = Destinations.delete_destination(destination)

    {:noreply, assign(socket, :destinations, list_destinations())}
  end

  defp list_destinations do
    Destinations.list_destinations()
  end
end
