defmodule ER.Subscriptions.Ingestor.S3.Server do
  @moduledoc """
  Manages the sending of events to S3
  """
  require Logger
  use GenServer
  use ER.Server
  # alias ExAws.S3
  alias ER.Repo

  def handle_continue(
        :load_state,
        %{
          "subscription" => subscription
        } = state
      ) do
    subscription = Repo.preload(subscription, :topic)

    state =
      state
      |> Map.put("subscription_s3_bucket", subscription.config["s3_bucket"])
      # default s3_ingestion_interval to 5 minutes
      |> Map.put(
        "subscription_s3_ingestion_interval",
        ER.to_integer(subscription.config["s3_ingestion_interval"] || "300_000")
      )
      |> Map.put("subscription_id", subscription.id)
      |> Map.put("subscription_topic_name", subscription.topic.name)
      |> Map.put(
        "timer",
        Process.send_after(self(), :tick, subscription.config["s3_ingestion_interval"])
      )

    {:noreply, state}
  end

  def handle_info(
        :tick,
        %{
          "subscription_s3_ingestion_interval" => ingestion_interval
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
end
