defmodule ER.Destinations.Pipeline.S3 do
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

    # dbg()

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
          s3: [
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
  def handle_message(_, %Message{} = message, %{
        destination: %{paused: false, config: _config} = _destination
      }) do
    Logger.debug("#{__MODULE__}.handle_message(#{inspect(message)}")

    Message.put_batcher(message, :s3)
  end

  def handle_message(_, message, context) do
    Logger.debug(
      "#{__MODULE__}.handle_message(_, #{inspect(message)}, #{inspect(context)}) do not handle message"
    )
  end

  @impl Broadway
  def handle_batch(
        :s3,
        messages,
        _batch_info,
        %{destination: %{paused: false, config: %{"s3_bucket" => bucket, "s3_region" => region}}} =
          _destination
      ) do
    now = DateTime.now!("Etc/UTC")

    jsonl =
      jsonl_encode_events(messages)

    ER.Container.s3().put_object!(region, bucket, build_events_file_name(now), jsonl)
    Logger.debug("#{__MODULE__}.handle_batch(#{inspect(messages)} successfully uploaded to S3.")
    messages
  end

  def build_events_file_name(now) do
    datetime = now |> DateTime.to_iso8601()
    folder = now |> DateTime.to_date() |> Date.to_string()
    "/#{folder}/#{datetime}-events.jsonl"
  end

  def jsonl_encode_events(messages) do
    Enum.map(messages, fn %{data: event} ->
      case Jason.encode(event) do
        {:ok, json} ->
          json

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  def name(id) do
    "destination:pipeline:s3:#{id}"
  end
end
