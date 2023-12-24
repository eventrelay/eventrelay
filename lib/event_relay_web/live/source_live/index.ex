defmodule ERWeb.SourceLive.Index do
  use ERWeb, :live_view

  alias ER.Sources
  alias ER.Sources.Source

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream(:sources, Sources.list_sources())
      |> assign(:topics, ER.Events.list_topics())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Source")
    |> assign(:source, Sources.get_source!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Source")
    |> assign(:source, %Source{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Sources")
    |> assign(:source, nil)
  end

  @impl true
  def handle_info({ERWeb.SourceLive.FormComponent, {:saved, source}}, socket) do
    {:noreply, stream_insert(socket, :sources, source)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    source = Sources.get_source!(id)
    {:ok, _} = Sources.delete_source(source)

    {:noreply, stream_delete(socket, :sources, source)}
  end
end
