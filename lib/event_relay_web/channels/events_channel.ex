defmodule ERWeb.EventsChannel do
  use ERWeb, :channel
  require Logger
  alias ER.Events.Event
  import ER, only: [atomize_map: 1, to_boolean: 1]

  @impl true
  def join("events:" <> destination_id, payload, socket) do
    ER.Events.ChannelCache.register_socket(self(), destination_id)

    case authorized?(payload) do
      {:ok, claims} ->
        api_key = ER.Accounts.get_api_key(claims["api_key_id"])

        socket =
          socket
          |> assign(:destination_id, destination_id)
          |> assign(:claims, claims)
          |> assign(:api_key, api_key)

        {:ok, socket}

      {:error, reason} ->
        Logger.error("Failed to authorize socket: #{inspect(reason)}")
        {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in(
        "publish_events",
        %{"topic" => topic, "durable" => durable, "events" => events} = payload,
        socket
      ) do
    request = ERWeb.Grpc.Eventrelay.PublishEventsRequest.new(atomize_map(payload))

    case Bosun.permit(socket.assigns.api_key, :request, request) do
      {:ok, _} ->
        {topic_name, topic_identifier} = ER.Events.Topic.parse_topic(topic)
        durable = to_boolean(durable)

        Enum.map(events, fn event ->
          %{
            name: Map.get(event, "name"),
            source: Map.get(event, "source"),
            data_json: Map.get(event, "data"),
            context: Map.get(event, "context"),
            occurred_at: Map.get(event, "occurred_at"),
            user_key: Map.get(event, "user_key"),
            group_key: Map.get(event, "group_key"),
            reference_key: Map.get(event, "reference_key"),
            trace_key: Map.get(event, "trace_key"),
            available_at: Map.get(event, "available_at"),
            anonymous_key: Map.get(event, "anonymous_key"),
            durable: durable,
            verified: true,
            topic_name: topic_name,
            topic_identifier: topic_identifier,
            data_schema_json: Map.get(event, "data_schema"),
            prev_id: Map.get(event, "prev_id")
          }
        end)
        |> Flamel.Task.stream(&produce_event/1)

        {:reply, {:ok, %{status: "ok"}}, socket}

      {:error, _context} ->
        {:reply, %{status: "unauthorized"}, socket}
    end
  end

  defp produce_event(event) do
    case ER.Events.produce_event_for_topic(event) do
      {:ok, %Event{} = event} ->
        Logger.debug("Published event: #{inspect(event)}")

      {:error, error} ->
        # TODO: provide a better error message
        Logger.error("Error creating event: #{inspect(error)}")
        nil
    end
  end

  defp authorized?(payload) do
    claims =
      payload["token"]
      |> to_string()
      |> ER.JWT.Token.get_claims()
      |> ER.unwrap_ok_or_nil()

    case claims do
      nil ->
        {:error, "no token provided"}

      claims ->
        {:ok, claims}
    end
  end
end
