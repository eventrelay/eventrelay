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
      |> assign(:query_error, nil)
      |> assign(:offset, 0)
      |> assign(:batch_size, 20)
      |> assign(:search_form, build_search_form())
      |> assign(:topic, topic)
      |> assign_events(nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
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

    query = params["query"]

    socket =
      socket
      |> apply_action(socket.assigns.live_action, params)
      |> assign(:search_form, build_search_form(query))
      |> assign_events(query)

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
    query = get_in(params, ["search_form", "query"]) || ""
    topic = socket.assigns.topic

    socket =
      socket
      |> assign(:search_form, build_search_form(query))
      |> assign(:offset, 0)
      |> assign_events(query)

    {:noreply,
     push_patch(socket,
       to:
         ~p"/topics/#{topic}/events?query=#{query}&offset=#{socket.assigns.offset}&batch_size=#{socket.assigns.batch_size}"
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

    results =
      if Flamel.present?(query) do
        case Predicated.Query.new(query) do
          {:ok, predicates} ->
            {:ok, predicates}

          {:error, unparsed: value} ->
            {:error, value}

          {:error, _} ->
            {:error, query}
        end
      else
        {:ok, []}
      end

    case results do
      {:ok, predicates} ->
        batched_result =
          ER.Events.list_events_for_topic(
            topic_name,
            offset: socket.assigns.offset,
            batch_size: ER.to_integer(socket.assigns.batch_size),
            topic_identifier: topic_identifier,
            predicates: predicates
          )

        socket
        |> assign(:events, batched_result.results)
        |> assign(:next_offset, batched_result.next_offset)
        |> assign(:previous_offset, batched_result.previous_offset)
        |> assign(:total_count, batched_result.total_count)
        |> assign(:query_error, nil)

      {:error, msg} ->
        socket
        |> assign(:events, [])
        |> assign(:offset, 0)
        |> assign(:next_offset, nil)
        |> assign(:previous_offset, nil)
        |> assign(:total_count, 0)
        |> assign(:batch_size, 20)
        |> assign(
          :query_error,
          "There is a syntax error in this portion of the query: \"#{msg}\""
        )
    end
  end

  defp build_search_form(query \\ "") do
    Ecto.Changeset.change(%ER.Events.SearchForm{}, %{query: query})
  end
end
