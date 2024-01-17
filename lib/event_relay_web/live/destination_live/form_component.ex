defmodule ERWeb.DestinationLive.FormComponent do
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
        <.input field={f[:name]} type="text" label="Name" />
        <.input
          field={f[:destination_type]}
          prompt="Pick a type"
          type="select"
          options={Ecto.Enum.mappings(ER.Destinations.Destination, :destination_type)}
          label="Type"
        />
        <.input
          prompt="Pick a topic"
          field={f[:topic_name]}
          type="select"
          options={topics_to_select_options(@topics)}
          label="Topic Name"
        />
        <.input field={f[:topic_identifier]} type="text" label="Topic Identifier" />
        <.input field={f[:group_key]} type="text" label="Group Key" />

        <p :if={Flamel.to_atom(f[:destination_type].value) in [:webhook, :file, :topic]}>
          Example Config
        </p>
        <.alert :if={Flamel.to_atom(f[:destination_type].value) == :webhook} color="info">
          <pre><%= ER.Destinations.Destination.base_config(:webhook) |> Jason.encode!(pretty: true) %></pre>
        </.alert>

        <.alert :if={Flamel.to_atom(f[:destination_type].value) == :file} color="info">
          <pre><%= ER.Destinations.Destination.base_config(:file) |> Jason.encode!(pretty: true) %></pre>
        </.alert>

        <.alert :if={Flamel.to_atom(f[:destination_type].value) == :topic} color="info">
          <pre><%= ER.Destinations.Destination.base_config(:topic) |> Jason.encode!(pretty: true) %></pre>
        </.alert>

        <.input
          :if={Flamel.to_atom(f[:destination_type].value) in [:webhook, :file, :topic]}
          field={f[:config_json]}
          type="textarea"
          label="Config"
        />
        <.input field={f[:query]} type="textarea" label="Query Filter" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Destination</.button>
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
    save_destination(socket, socket.assigns.action, destination_params)
  end

  defp save_destination(socket, :edit, destination_params) do
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

  defp save_destination(socket, :new, destination_params) do
    case Destinations.create_destination(destination_params) do
      {:ok, _destination} ->
        {:noreply,
         socket
         |> put_flash(:info, "Destination created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
