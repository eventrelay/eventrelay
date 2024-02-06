defmodule ERWeb.DestinationLive.ConfigFormComponent do
  use ERWeb, :live_component

  alias ER.Destinations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle></:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="destination-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div :if={Flamel.to_atom(f[:destination_type].value) in [:webhook, :file, :topic, :postgres]}>
          Example Config
          <.alert color="info">
            <pre><%= ER.Destinations.Destination.base_config(f[:destination_type].value) |> Jason.encode!(pretty: true) %></pre>
          </.alert>
        </div>

        <% # :if={Flamel.to_atom(f[:destination_type].value) in [:webhook, :file, :topic]} %>
        <.input field={f[:config_json]} type="textarea" label="Config" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Destination Config</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{destination: destination} = assigns, socket) do
    destination = %{destination | config_json: ER.Config.config_json(destination)}

    changeset = Destinations.change_destination(destination)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"destination" => destination_params}, socket) do
    changeset =
      socket.assigns.destination
      |> Destinations.change_destination(destination_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"destination" => destination_params}, socket) do
    save_destination(socket, destination_params)
  end

  defp save_destination(socket, destination_params) do
    case Destinations.update_destination(socket.assigns.destination, destination_params) do
      {:ok, _destination} ->
        {:noreply,
         socket
         |> put_flash(:info, "Destination updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
