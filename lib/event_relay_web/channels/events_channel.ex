defmodule ERWeb.EventsChannel do
  use ERWeb, :channel
  require Logger
  alias ER.Events.Event

  @impl true
  def join("events:" <> subscription_id, payload, socket) do
    ER.Container.channel_cache().register_socket(self(), subscription_id)

    case authorized?(payload) do
      {:ok, {producer_claims, consumer_claims}} ->
        producer_api_key = ER.Accounts.get_api_key(producer_claims["api_key_id"])
        consumer_api_key = ER.Accounts.get_api_key(consumer_claims["api_key_id"])

        socket =
          socket
          |> assign(:subscription_id, subscription_id)
          |> assign(:producer_claims, producer_claims)
          |> assign(:producer_api_key, producer_api_key)
          |> assign(:consumer_claims, consumer_claims)
          |> assign(:consumer_api_key, consumer_api_key)

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
    request = ERWeb.Grpc.Eventrelay.PublishEventsRequest.new(payload)

    case Bosun.permit(socket.assigns.producer_api_key, :request, request) do
      {:ok, _} ->
        response = %{status: "ok"}
        {topic_name, topic_identifier} = ER.Events.Topic.parse_topic(topic)
        durable = unless ER.boolean?(durable), do: false, else: durable

        Enum.map(events, fn event ->
          case ER.Events.produce_event_for_topic(%{
                 name: Map.get(event, "name"),
                 source: Map.get(event, "source"),
                 data_json: Map.get(event, "data"),
                 context: Map.get(event, "context"),
                 occurred_at: Map.get(event, "occurred_at"),
                 user_id: Map.get(event, "user_id"),
                 anonymous_id: Map.get(event, "anonymous_id"),
                 durable: durable,
                 topic_name: topic_name,
                 topic_identifier: topic_identifier
               }) do
            {:ok, %Event{} = event} ->
              Logger.debug("Published event: #{inspect(event)}")

            {:error, error} ->
              # TODO: provide a better error message
              Logger.error("Error creating event: #{inspect(error)}")
              nil
          end
        end)

        {:reply, {:ok, response}, socket}

      {:error, _context} ->
        {:reply, %{status: "unauthorized"}, socket}
    end
  end

  defp authorized?(payload) do
    producer_claims =
      payload["producer_token"]
      |> to_string()
      |> ER.JWT.Token.get_claims()
      |> ER.unwrap_ok_or_nil()

    consumer_claims =
      payload["consumer_token"]
      |> to_string()
      |> ER.JWT.Token.get_claims()
      |> ER.unwrap_ok_or_nil()

    case {producer_claims, consumer_claims} do
      {nil, nil} ->
        {:error, "no token provided"}

      {nil, consumer_claims} ->
        {:ok, {nil, consumer_claims}}

      {producer_claims, nil} ->
        {:ok, {producer_claims, nil}}

      {producer_claims, consumer_claims} ->
        {:ok, {producer_claims, consumer_claims}}
    end
  end
end
