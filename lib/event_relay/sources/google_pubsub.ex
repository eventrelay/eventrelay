defmodule ER.Sources.GooglePubSub do
  use Broadway

  require Logger
  alias ER.Sources.Source
  alias Broadway.Message
  alias ER.Events.Event
  alias ER.Repo
  import ER

  def start_link(opts) do
    source = opts[:source]

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {Source.get_broadway_producer(source), destination: source.config["destination"]}
      ],
      processors: [
        default: []
      ],
      batchers: [
        default: [
          batch_size: 10,
          batch_timeout: 2_000
        ]
      ],
      context: %{
        source: source
      }
    )
  end

  def handle_message(_, %Message{data: _data} = message, context) do
    try do
      case context[:source] do
        %Source{} = source ->
          source =
            source
            |> Repo.preload(:transformer)

          message
          |> Message.update_data(fn data ->
            ER.Transformers.factory(source.transformer)
            |> ER.Transformers.Transformation.perform(
              message: Jason.decode!(data),
              context: Source.build_context(source)
            )
          end)

        _ ->
          Logger.error(
            "ER.Sources.GooglePubSub.handle_message missing source in context context=#{inspect(context)}"
          )
      end
    rescue
      e ->
        Logger.error(
          "#{__MODULE__}.handle_message(#{inspect(message)}, #{inspect(context)} with e=#{inspect(e)}"
        )

        Message.failed(message, e.message)
    end
  end

  def handle_batch(_, messages, _batch_info, _context) do
    messages
    |> Enum.each(fn message ->
      # TODO: improve logging
      attrs =
        message.data
        |> safely_get("event")
        |> atomize_map()

      case ER.Events.produce_event_for_topic(attrs) do
        {:ok, %Event{} = event} ->
          Logger.debug("Created event: #{inspect(event)}")
          nil

        {:error, error} ->
          Logger.error("Error creating event: #{inspect(error)}")
          nil
      end
    end)

    messages
  end
end
