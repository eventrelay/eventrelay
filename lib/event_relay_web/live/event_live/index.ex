defmodule ERWeb.EventLive.Index do
  use ERWeb, :live_view

  alias ER.Events
  alias ER.Events.Event

  @impl true
  def mount(params, _session, socket) do
    topic = ER.Events.get_topic!(params["topic_id"])

    socket =
      socket
      |> assign(:topic, topic)
      |> assign(:events, list_events(topic))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Event")
    |> assign(:event, %Event{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Events")
    |> assign(:event, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    event = Events.get_event!(id)
    {:ok, _} = Events.delete_event(event)

    {:noreply, assign(socket, :events, list_events(socket.assigns.topic))}
  end

  defp list_events(topic) do
    {topic_name, topic_identifier} = ER.Events.Topic.parse_topic(topic)

    batched_result =
      ER.Events.list_events_for_topic(
        offset: 0,
        batch_size: 100_000,
        topic_name: topic_name,
        topic_identifier: topic_identifier
      )

    batched_result.results
  end
end
