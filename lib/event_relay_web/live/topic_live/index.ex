defmodule ERWeb.TopicLive.Index do
  use ERWeb, :live_view

  alias ER.Events
  alias ER.Events.Topic

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :topics, list_topics())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Topic")
    |> assign(:topic, %Topic{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Topic")
    |> assign(:topic, Events.get_topic(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Topics")
    |> assign(:topic, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    topic = Events.get_topic!(id)

    case Events.delete_topic(topic) do
      {:ok, _} ->
        {:noreply, assign(socket, :topics, list_topics())}

      {:error, msg} ->
        socket |> put_flash(:error, msg) |> push_navigate(to: socket.assigns.navigate)
    end
  end

  defp list_topics do
    Events.list_topics()
  end
end
