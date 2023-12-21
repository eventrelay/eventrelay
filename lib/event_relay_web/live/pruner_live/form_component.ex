defmodule ERWeb.PrunerLive.FormComponent do
  use ERWeb, :live_component

  alias ER.Pruners

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage pruner records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="pruner-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input
          field={@form[:type]}
          prompt="Pick a type"
          type="select"
          options={Ecto.Enum.mappings(ER.Pruners.Pruner, :type)}
          label="Type"
        />
        <.input field={@form[:config_json]} type="textarea" label="Config" />
        <.input field={@form[:query]} type="textarea" label="Query Filter" />
        <.input
          prompt="Pick a topic"
          field={@form[:topic_name]}
          type="select"
          options={topics_to_select_options(@topics)}
          label="Topic Name"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Pruner</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{pruner: pruner} = assigns, socket) do
    pruner = %{pruner | config_json: ER.Config.config_json(pruner)}
    changeset = Pruners.change_pruner(pruner)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"pruner" => pruner_params}, socket) do
    changeset =
      socket.assigns.pruner
      |> Pruners.change_pruner(pruner_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"pruner" => pruner_params}, socket) do
    save_pruner(socket, socket.assigns.action, pruner_params)
  end

  defp save_pruner(socket, :edit, pruner_params) do
    case Pruners.update_pruner(socket.assigns.pruner, pruner_params) do
      {:ok, pruner} ->
        notify_parent({:saved, pruner})

        {:noreply,
         socket
         |> put_flash(:info, "Pruner updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_pruner(socket, :new, pruner_params) do
    case Pruners.create_pruner(pruner_params) do
      {:ok, pruner} ->
        notify_parent({:saved, pruner})

        {:noreply,
         socket
         |> put_flash(:info, "Pruner created successfully")
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
