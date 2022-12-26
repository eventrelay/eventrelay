defmodule ERWeb.Grpc.EventRelay.Server do
  use GRPC.Server, service: ERWeb.Grpc.Eventrelay.EventRelay.Service

  alias ERWeb.Grpc.Eventrelay.{CreateEventRequest, CreateEventResponse}
  alias ER.Events.Event
  alias ER.Events.Topic
  alias ER.Repo

  @spec create_events(CreateEventRequest.t(), GRPC.Server.Stream.t()) ::
          CreateEventResponse.t()
  def create_events(request, _stream) do
    events = request.events

    new_events =
      Enum.map(events, fn event ->
        {topic_name, topic_identifier} = Topic.parse_topic(event.topic)

        new_event = %{
          name: event.name,
          source: event.source,
          data: event.data,
          context: event.context,
          occurred_at: event.occurred_at,
          topic_name: topic_name,
          topic_identifier: topic_identifier
        }

        # TODO: maybe setup some smart defaults and/or a dead letter queue
        if Event.changeset(%Event{}, new_event).valid? do
          new_event
        else
          nil
        end
      end)
      # For now just drop any invalid events
      |> Enum.reject(&is_nil/1)

    # Write code to insert the events into the database and do it in a transaction

    CreateEventResponse.new(eventIds: Enum.map(new_events, & &1.id))
  end
end

defmodule ERWeb.Grpc.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run(ERWeb.Grpc.EventRelay.Server)
end
