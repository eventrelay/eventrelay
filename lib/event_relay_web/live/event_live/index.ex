defmodule ERWeb.EventLive.Index do
  use ERWeb, :live_view

  alias ER.Events
  alias ER.Events.Event

  @impl true
  def mount(params, _session, socket) do
    topic = ER.Events.get_topic!(params["topic_id"])

    socket =
      socket
      |> assign(:query, nil)
      |> assign(:offset, 0)
      |> assign(:batch_size, 20)
      |> assign(:search_form, to_form(%{query: ""}))
      |> assign(:topic, topic)
      |> assign_events(nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # TODO: figure out serializing search_form in query string
    offset = params["offset"]

    socket =
      if offset do
        assign(socket, :offset, ER.to_integer(offset))
      else
        socket
      end

    batch_size = ER.to_integer(params["batch_size"])

    socket =
      if batch_size && batch_size > 0 do
        assign(socket, :batch_size, batch_size)
      else
        socket
      end

    socket =
      socket
      |> apply_action(socket.assigns.live_action, params)
      |> assign_events(params["search"])

    {:noreply, socket}
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
  def handle_event("search", params, socket) do
    IO.inspect(params: params)
    query = params["query"]
    topic = socket.assigns.topic

    socket =
      socket
      |> assign(:search_form, to_form(%{query: query}))
      |> assign_events(query)

    {:noreply,
     push_patch(socket,
       to:
         ~p"/topics/#{topic}/events?offset=#{socket.assigns.offset}&batch_size=#{socket.assigns.batch_size}"
     )}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    topic_name = socket.assigns.topic.name
    event = Events.get_event_for_topic!(id, topic_name: topic_name)
    {:ok, _} = Events.delete_event(event, topic_name: topic_name)

    {:noreply, assign_events(socket, [])}
  end

  defp assign_events(socket, query) do
    {topic_name, topic_identifier} = ER.Events.Topic.parse_topic(socket.assigns.topic)

    predicates =
      if Flamel.present?(query) do
        case Predicated.Query.new(query) do
          {:ok, predicates} -> predicates
          _ -> []
        end
      else
        []
      end

    batched_result =
      ER.Events.list_events_for_topic(
        offset: socket.assigns.offset,
        batch_size: ER.to_integer(socket.assigns.batch_size),
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        predicates: predicates
      )

    socket
    |> assign(:events, batched_result.results)
    |> assign(:next_offset, batched_result.next_offset)
    |> assign(:previous_offset, batched_result.previous_offset)
    |> assign(:total_count, batched_result.total_count)
  end
end
