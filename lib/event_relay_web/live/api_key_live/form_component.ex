defmodule ERWeb.ApiKeyLive.FormComponent do
  use ERWeb, :live_component

  alias ER.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage api_key records in your database.</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="api_key-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={f[:name]} type="text" label="Name" />
        <.input field={f[:status]} type="text" label="Status" />
        <.input field={f[:type]} type="text" label="Type" />
        <.input field={f[:group_key]} type="text" label="Group Key" />
        <.input field={f[:tls_hostname]} type="text" label="TLS Hostname" />
        <:actions>
          <.button phx-disable-with="Saving...">Save API key</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{api_key: api_key} = assigns, socket) do
    changeset = Accounts.change_api_key(api_key)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"api_key" => api_key_params}, socket) do
    changeset =
      socket.assigns.api_key
      |> Accounts.change_api_key(api_key_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"api_key" => api_key_params}, socket) do
    save_api_key(socket, socket.assigns.action, api_key_params)
  end

  defp save_api_key(socket, :edit, api_key_params) do
    case Accounts.update_api_key(socket.assigns.api_key, api_key_params) do
      {:ok, _api_key} ->
        {:noreply,
         socket
         |> put_flash(:info, "API key updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_api_key(socket, :new, api_key_params) do
    case Accounts.create_api_key(api_key_params) do
      {:ok, _api_key} ->
        {:noreply,
         socket
         |> put_flash(:info, "API key created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
