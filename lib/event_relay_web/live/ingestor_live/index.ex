defmodule ERWeb.IngestorLive.Index do
  use ERWeb, :live_view

  alias ER.Ingestors
  alias ER.Ingestors.Ingestor

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream(:ingestors, Ingestors.list_ingestors())
      |> assign(:topics, ER.Events.list_topics())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Ingestor")
    |> assign(:ingestor, Ingestors.get_ingestor!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Ingestor")
    |> assign(:ingestor, %Ingestor{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Ingestors")
    |> assign(:ingestor, nil)
  end

  @impl true
  def handle_info({ERWeb.IngestorLive.FormComponent, {:saved, ingestor}}, socket) do
    {:noreply, stream_insert(socket, :ingestors, ingestor)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    ingestor = Ingestors.get_ingestor!(id)
    {:ok, _} = Ingestors.delete_ingestor(ingestor)

    {:noreply, stream_delete(socket, :ingestors, ingestor)}
  end
end
