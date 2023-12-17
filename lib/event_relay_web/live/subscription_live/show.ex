defmodule ERWeb.SubscriptionLive.Show do
  use ERWeb, :live_view

  alias ER.Subscriptions

  @impl true
  def mount(_params, _session, socket) do
    topic_options = ER.Events.list_topics() |> Enum.map(fn topic -> {topic.name, topic.name} end)

    socket =
      socket
      |> assign(:topic_options, topic_options)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:subscription, Subscriptions.get_subscription!(id))}
  end

  defp page_title(:show), do: "Show Subscription"
  defp page_title(:edit), do: "Edit Subscription"
end
