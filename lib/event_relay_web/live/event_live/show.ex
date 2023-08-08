defmodule ERWeb.EventLive.Show do
  use ERWeb, :live_view

  alias ER.Events

  @impl true
  def mount(params, _session, socket) do
    topic = ER.Events.get_topic!(params["topic_id"])

    socket =
      socket
      |> assign(:topic, topic)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:event, Events.get_event_for_topic!(id, topic_name: socket.assigns.topic))}
  end

  defp page_title(:show), do: "Show Event"
end
