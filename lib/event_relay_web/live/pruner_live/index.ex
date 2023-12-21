defmodule ERWeb.PrunerLive.Index do
  use ERWeb, :live_view

  alias ER.Pruners
  alias ER.Pruners.Pruner

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream(:pruners, Pruners.list_pruners())
      |> assign(:topics, ER.Events.list_topics())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Pruner")
    |> assign(:pruner, Pruners.get_pruner!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Pruner")
    |> assign(:pruner, %Pruner{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Pruners")
    |> assign(:pruner, nil)
  end

  @impl true
  def handle_info({ERWeb.PrunerLive.FormComponent, {:saved, pruner}}, socket) do
    {:noreply, stream_insert(socket, :pruners, pruner)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    pruner = Pruners.get_pruner!(id)
    {:ok, _} = Pruners.delete_pruner(pruner)

    {:noreply, stream_delete(socket, :pruners, pruner)}
  end
end
