defmodule ERWeb.EventController do
  use ERWeb, :controller

  require Logger
  import ER
  alias ER.Events.Event

  action_fallback ERWeb.FallbackController

  # TODO: implement
  # def index(conn, _params) do
  #   events = Events.list_events()
  #   render(conn, :index, events: events)
  # end

  def publish(conn, %{"topic" => topic, "durable" => durable, "events" => events}) do
    {topic_name, topic_identifier} = ER.Events.Topic.parse_topic(topic)

    durable = unless ER.boolean?(durable), do: true, else: to_boolean(durable)

    unless ER.empty?(topic_name) do
      case Bosun.permit(conn.assigns.api_key, :publish_events, %Event{}, topic_name: topic_name) do
        {:ok, _context} ->
          events =
            Enum.map(events, fn event ->
              case ER.Events.produce_event_for_topic(%{
                     name: indifferent_get(event, :name),
                     source: indifferent_get(event, :source),
                     group_key: indifferent_get(event, :group_key),
                     reference_key: indifferent_get(event, :reference_key),
                     trace_key: indifferent_get(event, :trace_key),
                     data: indifferent_get(event, :data),
                     context: indifferent_get(event, :context),
                     occurred_at: indifferent_get(event, :occurred_at),
                     user_id: indifferent_get(event, :user_id),
                     anonymous_id: indifferent_get(event, :anonymous_id),
                     durable: durable,
                     topic_name: topic_name,
                     topic_identifier: topic_identifier
                   }) do
                {:ok, %Event{} = event} ->
                  event

                {:error, error} ->
                  # TODO: provide a better error message
                  Logger.error("Error creating event: #{inspect(error)}")
                  nil
              end
            end)
            |> Enum.reject(&is_nil/1)

          conn
          |> put_status(:created)
          |> render(:index, events: events)

        {:error, _context} ->
          conn
          |> put_status(:forbidden)
          |> render(:errors,
            errors: ["You are not permitted to perform this action"]
          )
      end
    else
      conn
      |> put_status(:conflict)
      |> render(:errors,
        errors: ["A topic must be provided"]
      )
    end
  end
end
