defmodule ERWeb.SourceLive.Show do
  use ERWeb, :live_view

  alias ER.Sources

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
    source = Sources.get_source!(id)

    webhook_base =
      ["#{uri.scheme}://#{source.key}:#{source.secret}@#{uri.host}", uri.port]
      |> Enum.join(":")

    webhook_url = "#{webhook_base}/webhooks/ingest/#{source.id}"

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:webhook_url, webhook_url)
     |> assign(:source, source)}
  end

  defp page_title(:show), do: "Show Source"
  defp page_title(:edit), do: "Edit Source"
end
