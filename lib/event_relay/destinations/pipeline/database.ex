defmodule ER.Destinations.Pipeline.Database do
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
        ],
        batchers: [
          database: [
            concurrency: broadway_config.batcher_concurrency,
            batch_size: broadway_config.batch_size,
            batch_timeout: broadway_config.batch_timeout
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
        message,
        %{
          destination: %{paused: false}
        } = context
      ) do
    Logger.debug("#{__MODULE__}.handle_message(#{inspect(message)}, #{inspect(context)}")

    Message.put_batcher(message, :database)
  end

  def handle_message(_, message, context) do
    Logger.debug(
      "#{__MODULE__}.handle_message(_, #{inspect(message)}, #{inspect(context)}) do not handle message"
    )
  end

  @impl Broadway
  def handle_batch(
        :database,
        messages,
        _batch_info,
        %{
          destination: %{paused: false} = destination
        }
      ) do
    destination
    |> ER.Destinations.Database.Factory.build()
    |> ER.Destinations.Database.insert(messages)
  end

  def handle_batch(batch, _messages, batch_info, context) do
    Logger.debug(
      "#{__MODULE__}.handle_batch(#{inspect(batch)}, _messages, #{inspect(batch_info)}, #{inspect(context)}) does not handle batch"
    )
  end

  def name(id) do
    "destination:pipeline:database:#{id}"
  end
end
