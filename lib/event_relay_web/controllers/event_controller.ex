defmodule ERWeb.EventController do
  use ERWeb, :controller

  require Logger
  import ER
  alias ER.Events.Event

  action_fallback ERWeb.FallbackController

  plug :check_topic
  plug :authorize

  def check_topic(conn, _opts) do
    topic = conn.params["topic"]
    {topic_name, topic_identifier} = ER.Events.Topic.parse_topic(topic)

    if ER.empty?(topic_name) do
      conn
      |> put_status(:conflict)
      |> render(:errors,
        errors: ["A topic must be provided"]
      )
      |> halt()
    else
      conn
      |> assign(:topic_name, topic_name)
      |> assign(:topic_identifier, topic_identifier)
    end
  end

  def authorize(conn, _opts) do
    if Bosun.permit?(conn.assigns.api_key, :publish_events, %Event{},
         topic_name: conn.assigns.topic_name
       ) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> render(:errors,
        errors: [
          "You are not permitted to perform this action for topic=#{inspect(conn.assigns.topic_name)}"
        ]
      )
      |> halt()
    end
  end

  def publish(conn, %{"durable" => durable, "events" => events}) do
    topic_name = conn.assigns.topic_name
    topic_identifier = conn.assigns.topic_identifier
    durable = to_boolean(durable)

    Enum.map(events, fn event ->
      %{
        name: indifferent_get(event, :name),
        source: indifferent_get(event, :source),
        group_key: indifferent_get(event, :group_key),
        reference_key: indifferent_get(event, :reference_key),
        trace_key: indifferent_get(event, :trace_key),
        user_key: indifferent_get(event, :user_key),
        anonymous_key: indifferent_get(event, :anonymous_key),
        data: indifferent_get(event, :data),
        context: indifferent_get(event, :context),
        occurred_at: indifferent_get(event, :occurred_at),
        available_at: indifferent_get(event, :available_at),
        durable: durable,
        verified: true,
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        prev_id: indifferent_get(event, :prev_id)
      }
    end)
    |> then(fn events ->
      ER.Events.Batcher.Server.add(topic_name, events)
    end)

    resp(conn, 201, "Created")
  end
end
