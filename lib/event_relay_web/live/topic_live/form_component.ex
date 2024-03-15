defmodule ERWeb.TopicLive.FormComponent do
  use ERWeb, :live_component

  alias ER.Events
  import Flamel.Wrap

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="topic-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input :if={@action == :new} field={f[:name]} type="text" label="name" />
        <fieldset class="flex flex-col gap-2">
          <legend>Events</legend>
          <.inputs_for :let={f_event} field={f[:event_configs]}>
            <div>
              <div class="flex gap-4 items-end">
                <div class="grow">
                  <.input class="mt-0" field={f_event[:name]} label="Event Name" />
                  <.input class="mt-0" type="textarea" field={f_event[:schema]} label="Event Schema" />
                  <.button
                    class="mt-2"
                    type="button"
                    phx-target={@myself}
                    phx-value-index={f_event.index}
                    phx-click="remove-event"
                  >
                    Remove
                  </.button>
                </div>
              </div>
            </div>
          </.inputs_for>
          <.button class="mt-2" type="button" phx-target={@myself} phx-click="add-event">Add</.button>
        </fieldset>
        <:actions>
          <.button phx-disable-with="Saving...">Save Topic</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{topic: topic} = assigns, socket) do
    changeset = Events.change_topic(topic)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("add-event", _, socket) do
    socket
    |> update(:changeset, fn changeset ->
      existing = Ecto.Changeset.get_embed(changeset, :event_configs)
      Ecto.Changeset.put_embed(changeset, :event_configs, existing ++ [%{}])
    end)
    |> noreply()
  end

  def handle_event("remove-event", %{"index" => index}, socket) do
    index = Flamel.to_integer(index)

    socket =
      update(socket, :changeset, fn changeset ->
        existing = Ecto.Changeset.get_field(changeset, :event_configs, [])
        configs = List.delete_at(existing, index)
        Ecto.Changeset.put_embed(changeset, :event_configs, configs)
      end)

    {:noreply, socket}
  end

  def handle_event("validate", %{"topic" => topic_params}, socket) do
    changeset =
      socket.assigns.topic
      |> Events.change_topic(topic_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"topic" => topic_params}, socket) do
    save_topic(socket, socket.assigns.action, topic_params)
  end

  def handle_event("save", %{}, socket) do
    params = %{"event_configs" => %{}}
    save_topic(socket, socket.assigns.action, params)
  end

  defp save_topic(socket, :new, topic_params) do
    case Events.create_topic(topic_params) do
      {:ok, _topic} ->
        {:noreply,
         socket
         |> put_flash(:info, "Topic created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp save_topic(socket, :edit, topic_params) do
    case Events.update_topic(socket.assigns.topic, topic_params) do
      {:ok, _topic} ->
        {:noreply,
         socket
         |> put_flash(:info, "Topic updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
