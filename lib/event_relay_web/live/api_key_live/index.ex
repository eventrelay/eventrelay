defmodule ERWeb.ApiKeyLive.Index do
  use ERWeb, :live_view

  alias ER.Accounts
  alias ER.Accounts.ApiKey

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :api_keys, list_api_keys())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit API key")
    |> assign(:api_key, Accounts.get_api_key!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New API key")
    |> assign(:api_key, %ApiKey{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing API keys")
    |> assign(:api_key, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    api_key = Accounts.get_api_key!(id)
    {:ok, _} = Accounts.delete_api_key(api_key)

    {:noreply, assign(socket, :api_keys, list_api_keys())}
  end

  defp list_api_keys do
    Accounts.list_api_keys()
  end
end
