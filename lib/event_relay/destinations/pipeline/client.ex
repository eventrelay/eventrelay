defmodule ER.Destinations.Pipeline.Client do
  require Logger
  @behaviour OffBroadwayEcto.Client

  @impl true
  def prepare_for_start(opts) do
    destination = get_destination(opts)
    ER.Destinations.QueuedEvents.Server.factory(destination.id)

    if destination.destination_type == :database do
      destination
      |> ER.Destinations.Database.Factory.build()
      |> ER.Destinations.Database.prepare_for_start()
    end
  end

  @impl true
  def receive_messages(demand, opts) do
    Logger.debug("#{__MODULE__}.receive_messages(#{inspect(demand)}, #{inspect(opts)}")
    destination = get_destination(opts)
    ER.Destinations.QueuedEvents.Server.factory(destination.id)

    ER.Destinations.QueuedEvents.Server.pull_queued_events(
      destination.id,
      demand
    )
  end

  @impl true
  def handle_failed([], _opts) do
    :ok
  end

  def handle_failed(messages, opts) do
    destination = get_destination(opts)

    event_ids = Enum.map(messages, fn %{data: event} -> event.id end)

    Logger.error("event_ids=#{inspect(event_ids)}")

    ER.Destinations.QueuedEvents.Server.unlocked_queued_events(
      destination.id,
      event_ids
    )

    :ok
  end

  @impl true
  def handle_successful(_messages, _opts) do
    :ok
  end

  defp get_destination(opts) do
    client_opts = Map.get(opts, :client_options, [])
    client_opts[:destination]
  end
end
