defmodule ERWeb.EventLive.Index do
  use ERWeb, :live_view

  alias ER.Events
  alias ER.Events.Event
  import ER

  @impl true
  def mount(params, _session, socket) do
    topic = ER.Events.get_topic!(params["topic_id"])

    socket =
      socket
      |> assign(:query, nil)
      |> assign(:offset, 0)
      |> assign(:batch_size, 20)
      |> assign(:search_form, build_empty_search_form())
      |> assign(:topic, topic)
      |> assign_events([])

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

    filters = ER.Filter.translate(socket.assigns.search_form.data.event_filters)

    socket =
      socket
      |> apply_action(socket.assigns.live_action, params)
      |> assign_events(filters)

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
  def handle_event("search", %{"search_form" => %{"event_filters" => event_filters}}, socket) do
    topic = socket.assigns.topic

    [transformed_filters, untransformed_filters] =
      Map.values(event_filters)
      |> Enum.reduce([[], []], fn filter, [transformed, untransformed] ->
        transformed_filter =
          Map.update!(filter, "comparison", &ER.Filter.translate_comparison/1)
          |> atomize_map()

        [[transformed_filter | transformed], [filter | untransformed]]
      end)

    event_filters =
      Enum.reduce(untransformed_filters, [], fn filter, acc ->
        [struct(ER.Events.EventFilter, atomize_map(filter)) | acc]
      end)

    search_form = Ecto.Changeset.change(%ER.Events.SearchForm{event_filters: event_filters}, %{})

    socket =
      socket
      |> assign(:search_form, search_form)
      |> assign_events(transformed_filters)

    {:noreply,
     push_patch(socket,
       to:
         ~p"/topics/#{topic}/events?offset=#{socket.assigns.offset}&batch_size=#{socket.assigns.batch_size}"
     )}
  end

  @impl true
  def handle_event("clear_search_form", _, socket) do
    socket =
      socket
      |> assign(:search_form, build_empty_search_form())
      |> assign_events([])

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_filter", params, socket) do
    index = ER.to_integer(params["index"])
    search_form = socket.assigns.search_form
    data = search_form.data

    search_form = %{
      search_form
      | data: %{data | event_filters: List.delete_at(data.event_filters, index)}
    }

    transformed_filters = ER.Filter.translate(search_form.data.event_filters)

    socket =
      socket
      |> assign(:search_form, search_form)
      |> assign_events(transformed_filters)

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_filter", _params, socket) do
    search_form = socket.assigns.search_form
    data = search_form.data

    search_form = %{
      search_form
      | data: %{data | event_filters: [%ER.Events.EventFilter{} | data.event_filters]}
    }

    socket =
      socket
      |> assign(:search_form, search_form)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    topic_name = socket.assigns.topic.name
    event = Events.get_event_for_topic!(id, topic_name: topic_name)
    {:ok, _} = Events.delete_event(event, topic_name: topic_name)

    {:noreply, assign_events(socket, [])}
  end

  defp assign_events(socket, filters) do
    {topic_name, topic_identifier} = ER.Events.Topic.parse_topic(socket.assigns.topic)

    batched_result =
      ER.Events.list_events_for_topic(
        offset: socket.assigns.offset,
        batch_size: ER.to_integer(socket.assigns.batch_size),
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        filters: filters
      )

    socket
    |> assign(:events, batched_result.results)
    |> assign(:next_offset, batched_result.next_offset)
    |> assign(:previous_offset, batched_result.previous_offset)
    |> assign(:total_count, batched_result.total_count)
  end

  defp build_empty_search_form() do
    Ecto.Changeset.change(%ER.Events.SearchForm{event_filters: [%ER.Events.EventFilter{}]}, %{})
  end
end
