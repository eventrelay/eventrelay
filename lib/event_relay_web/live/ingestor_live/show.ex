defmodule ERWeb.IngestorLive.Show do
  use ERWeb, :live_view

  alias ER.Ingestors

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:topics, ER.Events.list_topics())

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    uri = socket.assigns[:current_host]
    ingestor = Ingestors.get_ingestor!(id)

    webhook_base =
      ["#{uri.scheme}://#{ingestor.key}:#{ingestor.secret}@#{uri.host}", uri.port]
      |> Enum.join(":")

    webhook_url = "#{webhook_base}/webhooks/ingest/#{ingestor.id}"

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:webhook_url, webhook_url)
     |> assign(:ingestor, ingestor)}
  end

  defp page_title(:show), do: "Show Ingestor"
  defp page_title(:edit), do: "Edit Ingestor"
end
