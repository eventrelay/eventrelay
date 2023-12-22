defmodule ERWeb.IngestorLive.FormComponent do
  use ERWeb, :live_component

  alias ER.Ingestors

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage ingestor records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="ingestor-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:type]}
          prompt="Pick a type"
          type="select"
          options={Ecto.Enum.mappings(ER.Ingestors.Ingestor, :type)}
          label="Type"
        />
        <.input field={@form[:config_json]} type="textarea" label="Config" />
        <.input
          prompt="Pick a topic"
          field={@form[:topic_name]}
          type="select"
          options={topics_to_select_options(@topics)}
          label="Topic Name"
        />
        <.input field={@form[:source]} type="text" label="Source" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Ingestor</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{ingestor: ingestor} = assigns, socket) do
    ingestor = %{ingestor | config_json: ER.Config.config_json(ingestor)}
    changeset = Ingestors.change_ingestor(ingestor)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"ingestor" => ingestor_params}, socket) do
    changeset =
      socket.assigns.ingestor
      |> Ingestors.change_ingestor(ingestor_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"ingestor" => ingestor_params}, socket) do
    save_ingestor(socket, socket.assigns.action, ingestor_params)
  end

  defp save_ingestor(socket, :edit, ingestor_params) do
    case Ingestors.update_ingestor(socket.assigns.ingestor, ingestor_params) do
      {:ok, ingestor} ->
        notify_parent({:saved, ingestor})

        {:noreply,
         socket
         |> put_flash(:info, "Ingestor updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_ingestor(socket, :new, ingestor_params) do
    case Ingestors.create_ingestor(ingestor_params) do
      {:ok, ingestor} ->
        notify_parent({:saved, ingestor})

        {:noreply,
         socket
         |> put_flash(:info, "Ingestor created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
