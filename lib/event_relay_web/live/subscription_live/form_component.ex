defmodule ERWeb.SubscriptionLive.FormComponent do
  use ERWeb, :live_component

  alias ER.Subscriptions

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage subscription records in your database.</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="subscription-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :name}} type="text" label="name" />
        <.input field={{f, :offset}} type="number" label="offset" />
        <.input field={{f, :topic_name}} type="text" label="topic_name" />
        <.input field={{f, :pull}} type="checkbox" label="pull" />
        <.input field={{f, :ordered}} type="checkbox" label="ordered" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Subscription</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{subscription: subscription} = assigns, socket) do
    changeset = Subscriptions.change_subscription(subscription)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"subscription" => subscription_params}, socket) do
    changeset =
      socket.assigns.subscription
      |> Subscriptions.change_subscription(subscription_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"subscription" => subscription_params}, socket) do
    save_subscription(socket, socket.assigns.action, subscription_params)
  end

  defp save_subscription(socket, :edit, subscription_params) do
    case Subscriptions.update_subscription(socket.assigns.subscription, subscription_params) do
      {:ok, _subscription} ->
        {:noreply,
         socket
         |> put_flash(:info, "Subscription updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_subscription(socket, :new, subscription_params) do
    case Subscriptions.create_subscription(subscription_params) do
      {:ok, _subscription} ->
        {:noreply,
         socket
         |> put_flash(:info, "Subscription created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
