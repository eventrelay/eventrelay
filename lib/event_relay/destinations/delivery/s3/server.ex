defmodule ER.Destinations.Delivery.S3.Server do
  @moduledoc """
  Manages the sending of events to S3
  """
  require Logger
  use GenServer
  use ER.Server
  alias ER.Repo
  alias ER.Destinations

  def handle_continue(
        :load_state,
        %{
          "destination" => destination
        } = state
      ) do
    destination = Repo.preload(destination, :topic)

    state =
      state
      |> Map.put("destination_s3_bucket", destination.config["s3_bucket"])
      # default s3_sync_interval to 5 minutes
      |> Map.put(
        "destination_s3_sync_interval",
        ER.to_integer(destination.config["s3_sync_interval"] || "300_000")
      )
      |> Map.put("destination_id", destination.id)
      |> Map.put("destination_topic_name", destination.topic.name)
      |> Map.put(
        "timer",
        Process.send_after(self(), :tick, destination.config["s3_sync_interval"])
      )

    {:noreply, state}
  end

  def handle_info(
        :tick,
        %{
          "destination_s3_sync_interval" => sync_interval
        } = state
      ) do
    try do
      sync!(state)
    rescue
      e in RuntimeError ->
        Logger.error(
          "ER.Destinations.Delivery.S3.Server.handle_info(:tick) exception=#{inspect(e)}"
        )

        Logger.error(Exception.format(:error, e, __STACKTRACE__))
    after
      new_timer = Process.send_after(self(), :tick, sync_interval)
      state = Map.put(state, "timer", new_timer)
      {:noreply, state}
    end
  end

  def sync!(%{
        "destination_s3_bucket" => bucket,
        "destination_topic_name" => destination_topic_name,
        "destination_id" => destination_id
      }) do
    Logger.debug("#{__MODULE__}.sync on node=#{inspect(Node.self())}")

    now = DateTime.now!("Etc/UTC")
    # query for deliveries that are pending for this destination
    deliveries =
      Destinations.list_deliveries_for_destination(
        destination_topic_name,
        destination_id,
        status: :pending
      )

    {jsonl, _events} =
      jsonl_encode_delivery_events(destination_topic_name, deliveries)

    case ER.Container.s3().put_object(bucket, build_events_file_name(now), jsonl) do
      {:ok, _result} ->
        Destinations.update_all_deliveries(destination_topic_name, deliveries,
          set: [staus: "success"]
        )

      {:error, _message} ->
        Destinations.update_all_deliveries(destination_topic_name, deliveries,
          set: [staus: "failure"]
        )
    end
  end

  def build_events_file_name(now) do
    datetime = now |> DateTime.to_iso8601()
    folder = now |> DateTime.to_date() |> Date.to_string()
    "/#{folder}/#{datetime}-events.jsonl"
  end

  def jsonl_encode_delivery_events(topic_name, deliveries) do
    events = Destinations.list_events_for_deliveries(topic_name, deliveries)

    jsonl =
      Enum.map(events, fn event ->
        case Jason.encode(event) do
          {:ok, json} ->
            json

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n")

    {jsonl, events}
  end

  @spec name(binary()) :: binary()
  def name(id) do
    "s3_delivery:" <> id
  end

  def handle_terminate(reason, state) do
    sync!(state)

    case reason do
      :shutdown ->
        :ok

      _ ->
        Logger.error("S3 Delivery server terminated unexpectedly: #{inspect(reason)}")
        Logger.debug("S3 Delivery server state: #{inspect(state)}")
    end
  end

  @spec tick_interval() :: integer()
  def tick_interval(tick_interval \\ nil) do
    tick_interval ||
      ER.to_integer(System.get_env("ER_SUBSCRIPTION_SERVER_TICK_INTERVAL") || "5000")
  end
end
