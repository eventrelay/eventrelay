defmodule ER.Destinations.Pipeline.Topic do
  use Broadway
  use ER.Destinations.Pipeline.Base

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
  def handle_message(
        _,
        %Message{data: event} = message,
        %{
          destination: %{paused: false, config: %{"topic_name" => topic_name}} = destination
        } = context
      ) do
    Logger.debug("#{__MODULE__}.handle_message(#{inspect(message)}, #{inspect(context)}")

    case ER.Destinations.Topic.forward(topic_name, event, destination) do
      {:ok, new_event} ->
        Message.update_data(message, fn _event ->
          new_event
        end)

      {:error, reason} ->
        Message.failed(message, "#{inspect(reason)}")
    end

    message
  end

  def handle_message(_, message, context) do
    Logger.debug(
      "#{__MODULE__}.handle_message(_, #{inspect(message)}, #{inspect(context)}) do not handle message"
    )
  end

  def name(id) do
    "destination:pipeline:topic:#{id}"
  end
end
