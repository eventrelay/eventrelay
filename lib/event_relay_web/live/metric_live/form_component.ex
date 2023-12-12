defmodule ERWeb.MetricLive.FormComponent do
  use ERWeb, :live_component

  alias ER.Metrics

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage metric records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="metric-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:topic_name]} type="text" label="Topic Name" />
        <.input field={@form[:topic_identifier]} type="text" label="Topic Identifier" />
        <.input field={@form[:field_path]} type="text" label="Field path" />
        <.input field={@form[:type]} type="text" label="Type" />
        <.input field={@form[:query]} type="textarea" label="Query" />
        <.input field={@form[:produce_update_event]} type="checkbox" label="Produce Update Event" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Metric</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{metric: metric} = assigns, socket) do
    changeset = Metrics.change_metric(metric)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"metric" => metric_params}, socket) do
    changeset =
      socket.assigns.metric
      |> Metrics.change_metric(metric_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"metric" => metric_params}, socket) do
    save_metric(socket, socket.assigns.action, metric_params)
  end

  defp save_metric(socket, :edit, metric_params) do
    case Metrics.update_metric(socket.assigns.metric, metric_params) do
      {:ok, metric} ->
        notify_parent({:saved, metric})

        {:noreply,
         socket
         |> put_flash(:info, "Metric updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_metric(socket, :new, metric_params) do
    case Metrics.create_metric(metric_params) do
      {:ok, metric} ->
        notify_parent({:saved, metric})

        {:noreply,
         socket
         |> put_flash(:info, "Metric created successfully")
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
