defmodule ERWeb.SourceLive.FormComponent do
  use ERWeb, :live_component

  alias ER.Sources

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="source-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:type]}
          prompt="Pick a type"
          type="select"
          options={Ecto.Enum.mappings(ER.Sources.Source, :type)}
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
        <.input field={@form[:source]} type="text" label="Event Source Value" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Source</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{source: source} = assigns, socket) do
    source = %{source | config_json: ER.Config.config_json(source)}
    changeset = Sources.change_source(source)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"source" => source_params}, socket) do
    changeset =
      socket.assigns.source
      |> Sources.change_source(source_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"source" => source_params}, socket) do
    save_source(socket, socket.assigns.action, source_params)
  end

  defp save_source(socket, :edit, source_params) do
    case Sources.update_source(socket.assigns.source, source_params) do
      {:ok, source} ->
        notify_parent({:saved, source})

        {:noreply,
         socket
         |> put_flash(:info, "Source updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_source(socket, :new, source_params) do
    case Sources.create_source(source_params) do
      {:ok, source} ->
        notify_parent({:saved, source})

        {:noreply,
         socket
         |> put_flash(:info, "Source created successfully")
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
