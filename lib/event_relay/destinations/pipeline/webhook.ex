defmodule ER.Destinations.Pipeline.Webhook do
  use Broadway
  use ER.Destinations.Pipeline.Base
  alias ER.Events
  alias ER.Destinations.Webhook
  alias ER.Destinations
  import Flamel.Wrap
  alias ER.Repo

  def start_link(opts) do
    broadway_config = get_broadway_config(opts[:destination])

    context = %{
      destination: broadway_config.destination
    }

    Logger.debug(
      "#{__MODULE__}.start_link opts=#{inspect(opts)} and broadway_config=#{inspect(broadway_config)}"
    )

    result =
      Broadway.start_link(__MODULE__,
        name: broadway_config.name,
        producer: [
          module:
            {OffBroadwayEcto.Producer,
             client: {ER.Destinations.Pipeline.Client, [destination: broadway_config.destination]},
             pull_interval: broadway_config.pull_interval}
        ],
        context: context,
        processors: [
          default: [
            concurrency: broadway_config.processor_concurrency,
            min_demand: broadway_config.processor_min_demand,
            max_demand: broadway_config.processor_max_demand
          ]
        ]
      )

    Logger.debug("#{__MODULE__}.start_link with result=#{inspect(result)}")

    result
  end

  @impl Broadway
  def process_name({:via, module, {registry, name}}, base_name) do
    name = {:via, module, {registry, "#{base_name}.Broadway.#{name}"}}
    Logger.debug("#{__MODULE__}.process_name with name=#{inspect(name)}")
    name
  end

  @impl Broadway
  def handle_message(_, %Message{data: event} = message, %{destination: destination}) do
    Logger.debug("#{__MODULE__}.handle_message(#{inspect(message)}, #{inspect(destination)}")

    try do
      topic_name = destination.topic_name

      delivery =
        ER.Destinations.get_or_create_delivery_for_topic_by_event_id(
          topic_name,
          %{event_id: event.id, destination_id: destination.id, status: :pending}
        )
        |> Flamel.Wrap.unwrap_ok!()
        |> Repo.preload(:destination)

      process_message(message, delivery)
    rescue
      e ->
        Logger.error(
          "#{__MODULE__}.handle_message(#{inspect(message)}, #{inspect(destination)} with e=#{inspect(e)}"
        )

        Message.failed(message, e.message)
    end
  end

  def process_message(message, delivery) do
    destination = delivery.destination

    response =
      Webhook.request(
        destination,
        message.data
      )
      |> Webhook.handle_response()

    attempts = [
      %{"response" => unwrap(response), "attempted_at" => DateTime.utc_now()} | delivery.attempts
    ]

    {message, _delivery} =
      if success?(response) do
        handle_success(message, delivery, attempts)
      else
        handle_retry(message, delivery, attempts)
      end

    message
  end

  def handle_success(message, delivery, attempts) do
    {message, update_delivery(delivery, %{status: :success, attempts: attempts})}
  end

  def handle_retry(message, delivery, attempts) do
    case ER.Destinations.Pipeline.Webhook.Retries.next(delivery.destination, delivery, attempts) do
      {%{halt?: true}, nil} ->
        # failure but we don't want to fail the message
        {message, update_delivery(delivery, %{status: :failure, attempts: attempts})}

      {_strategy, available_at} ->
        # lets retry again at
        Message.update_data(message, fn event ->
          update_event(event, delivery, %{available_at: available_at})
        end)
        |> Message.failed("retry")
        |> then(fn message ->
          {message, update_delivery(delivery, %{status: :pending, attempts: attempts})}
        end)
    end
  end

  def update_event(event, delivery, attrs \\ %{}) do
    case Events.update_event(event, attrs) do
      {:ok, event} ->
        event

      error ->
        Logger.error(
          "#{__MODULE__}.update_event(#{inspect(event)}, #{inspect(delivery)}, #{inspect(attrs)}) with error=#{inspect(error)}"
        )

        event
    end
  end

  def update_delivery(delivery, attrs \\ %{}) do
    case Destinations.update_delivery(delivery, attrs) do
      {:ok, delivery} ->
        delivery

      error ->
        Logger.error(
          "#{__MODULE__}.update_delivery(#{inspect(delivery)}, #{inspect(attrs)} with error=#{inspect(error)}"
        )

        delivery
    end
  end

  def success?({:ok, _}) do
    true
  end

  def success?({:error, _}) do
    false
  end

  def name(id) do
    "destination:pipeline:webhook:#{id}"
  end
end
