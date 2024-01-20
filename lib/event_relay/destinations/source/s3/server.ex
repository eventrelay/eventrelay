defmodule ER.Destinations.Source.S3.Server do
  @moduledoc """
  Manages the sending of events to S3
  """
  require Logger
  use GenServer
  use ER.Server.Base
  use ER.Horde.Server
  # alias ExAws.S3
  alias ER.Repo

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
      # default s3_ingestion_interval to 5 minutes
      |> Map.put(
        "destination_s3_ingestion_interval",
        ER.to_integer(destination.config["s3_ingestion_interval"] || "300_000")
      )
      |> Map.put("destination_id", destination.id)
      |> Map.put("destination_topic_name", destination.topic.name)
      |> Map.put(
        "timer",
        Process.send_after(self(), :tick, destination.config["s3_ingestion_interval"])
      )

    {:noreply, state}
  end

  def handle_info(
        :tick,
        %{
          "destination_s3_ingestion_interval" => ingestion_interval
        } = state
      ) do
    new_timer = Process.send_after(self(), :tick, ingestion_interval)
    state = Map.put(state, "timer", new_timer)
    {:noreply, state}
  end

  @spec name(binary()) :: binary()
  def name(id) do
    "s3_delivery:" <> id
  end

  def handle_terminate(reason, state) do
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
