defmodule ERWeb.ApiKeyLive.Show do
  use ERWeb, :live_view

  alias ER.Accounts
  alias ER.Repo

  @impl true
  def mount(_params, _session, socket) do
    topics = ER.Events.list_topics()
    destinations = ER.Destinations.list_destinations()
    socket = socket |> assign(:topics, topics) |> assign(:destinations, destinations)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    api_key =
      Accounts.get_api_key!(id)
      |> Repo.preload(:topics)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:api_key, api_key)}
  end

  @impl true
  def handle_event("add_topic", %{"topic_id" => topic_id}, socket) do
    topic = ER.Events.get_topic!(topic_id)
    api_key = socket.assigns.api_key
    {:ok, _} = ER.Accounts.create_api_key_topic(api_key, topic)

    api_key = Repo.reload(api_key)

    socket =
      socket
      |> assign(:api_key, api_key)
      |> push_patch(to: ~p"/api_keys/#{api_key}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_topic", %{"topic_id" => topic_id}, socket) do
    topic = ER.Events.get_topic!(topic_id)
    api_key = socket.assigns.api_key
    api_key_topic = ER.Accounts.get_api_key_topic(api_key, topic)
    {:ok, _} = ER.Accounts.delete_api_key_topic(api_key_topic)
    api_key = Repo.reload(api_key)

    socket =
      socket
      |> assign(:api_key, api_key)
      |> push_patch(to: ~p"/api_keys/#{api_key}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_destination", %{"destination_id" => destination_id}, socket) do
    destination = ER.Destinations.get_destination!(destination_id)
    api_key = socket.assigns.api_key
    {:ok, _} = ER.Accounts.create_api_key_destination(api_key, destination)

    api_key = Repo.reload(api_key)

    socket =
      socket
      |> assign(:api_key, api_key)
      |> push_patch(to: ~p"/api_keys/#{api_key}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_destination", %{"destination_id" => destination_id}, socket) do
    destination = ER.Destinations.get_destination!(destination_id)
    api_key = socket.assigns.api_key
    api_key_destination = ER.Accounts.get_api_key_destination(api_key, destination)
    {:ok, _} = ER.Accounts.delete_api_key_destination(api_key_destination)
    api_key = Repo.reload(api_key)

    socket =
      socket
      |> assign(:api_key, api_key)
      |> push_patch(to: ~p"/api_keys/#{api_key}")

    {:noreply, socket}
  end

  defp page_title(:show), do: "Show API Key"
  defp page_title(:edit), do: "Edit API Key"
end
