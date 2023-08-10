defmodule ER.Ingestors.GooglePubSub do
  use Broadway

  require Logger
  alias ER.Ingestors.Ingestor
  alias Broadway.Message
  alias ER.Events.Event
  alias ER.Repo
  import ER

  def start_link(opts) do
    ingestor = opts[:ingestor]

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {Ingestor.get_broadway_producer(ingestor),
           subscription: ingestor.config["subscription"]}
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
        ingestor: ingestor
      }
    )
  end

  def handle_message(_, %Message{data: _data} = message, context) do
    case context[:ingestor] do
      %Ingestor{} = ingestor ->
        ingestor =
          ingestor
          |> Repo.preload(:transformer)

        message
        |> Message.update_data(fn data ->
          ER.Transformers.run(
            ingestor.transformer,
            message: Jason.decode!(data),
            context: Ingestor.build_context(ingestor)
          )
        end)

      _ ->
        Logger.error(
          "ER.Ingestors.GooglePubSub.handle_message missing ingestor in context context=#{inspect(context)}"
        )
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
