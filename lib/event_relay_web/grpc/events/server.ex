defmodule ERWeb.Grpc.EventRelay.Events.Server do
  use GRPC.Server, service: ERWeb.Grpc.Eventrelay.Events.Service
  require Logger

  alias ERWeb.Grpc.Eventrelay.{
    PublishEventsRequest,
    PublishEventsResponse,
    PullEventsRequest,
    PullEventsResponse,
    PullQueuedEventsRequest,
    PullQueuedEventsResponse,
    UnLockQueuedEventsRequest,
    UnLockQueuedEventsResponse
  }

  alias ERWeb.Grpc.Eventrelay.Event, as: GrpcEvent
  alias ER.Events.Event

  @spec publish_events(PublishEventsRequest.t(), GRPC.Server.Stream.t()) ::
          PublishEventsResponse.t()
  def publish_events(request, _stream) do
    events = request.events
    topic = request.topic
    {topic_name, topic_identifier} = ER.Events.Topic.parse_topic(topic)
    verified = true

    if topic_name do
      events =
        Enum.map(events, fn event ->
          case ER.Events.produce_event_for_topic(%{
                 name: Map.get(event, :name),
                 source: Map.get(event, :source),
                 group_key: Map.get(event, :group_key),
                 reference_key: Map.get(event, :reference_key),
                 trace_key: Map.get(event, :trace_key),
                 data_json: Map.get(event, :data),
                 context: Map.get(event, :context),
                 occurred_at: Map.get(event, :occurred_at),
                 user_id: Map.get(event, :user_id),
                 anonymous_id: Map.get(event, :anonymous_id),
                 durable: request.durable,
                 verified: verified,
                 topic_name: topic_name,
                 topic_identifier: topic_identifier,
                 data_schema_json: Map.get(event, :data_schema),
                 prev_id: Map.get(event, :prev_id)
               }) do
            {:ok, %Event{} = event} ->
              build_event(event, topic)

            {:error, error} ->
              # TODO: provide a better error message
              Logger.error("Error creating event: #{inspect(error)}")
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      PublishEventsResponse.new(events: events)
    else
      raise GRPC.RPCError,
        status: GRPC.Status.invalid_argument(),
        message: "A topic must be provided to publish_events"
    end
  end

  @spec pull_events(PullEventsRequest.t(), GRPC.Server.Stream.t()) :: PullEventsResponse.t()
  def pull_events(request, _stream) do
    topic = request.topic
    {topic_name, topic_identifier} = ER.Events.Topic.parse_topic(topic)
    offset = if request.offset == 0, do: nil, else: request.offset
    batch_size = if request.batch_size == 0, do: 100, else: request.batch_size
    batch_size = if batch_size > 1000, do: 100, else: batch_size
    # TODO: make max batch_size configurable

    try do
      batched_results =
        ER.Events.list_events_for_topic(
          offset: offset,
          batch_size: batch_size,
          topic_name: topic_name,
          topic_identifier: topic_identifier,
          query: request.query
        )

      events = Enum.map(batched_results.results, &build_event(&1, topic))

      PullEventsResponse.new(
        events: events,
        next_offset: batched_results.next_offset,
        previous_offset: batched_results.previous_offset,
        total_count: batched_results.total_count,
        total_batches: batched_results.total_batches
      )
    rescue
      e in ER.Filter.BadFieldError ->
        raise GRPC.RPCError,
          status: GRPC.Status.invalid_argument(),
          message: e.message
    end
  end

  @spec pull_queued_events(PullQueuedEventsRequest.t(), GRPC.Server.Stream.t()) ::
          PullEventsResponse.t()
  def pull_queued_events(request, _stream) do
    destination =
      ER.Destinations.get_destination!(request.destination_id)

    # ensure we have the queued events server started. this is a noop if it is already started
    ER.Destinations.QueuedEvents.Server.factory(destination.id)

    batch_size = if request.batch_size == 0, do: 100, else: request.batch_size
    batch_size = if batch_size > 1000, do: 100, else: batch_size

    try do
      events =
        ER.Destinations.QueuedEvents.Server.pull_queued_events(
          destination_id: request.destination_id,
          batch_size: batch_size
        )

      topic_name = destination.topic_name
      topic_identifier = destination.topic_identifier
      full_topic = ER.Events.Topic.build_topic(topic_name, topic_identifier)
      events = Enum.map(events, &build_event(&1, full_topic))

      PullQueuedEventsResponse.new(events: events)
    rescue
      e in ER.Filter.BadFieldError ->
        raise GRPC.RPCError,
          status: GRPC.Status.invalid_argument(),
          message: e.message
    end
  end

  @spec unlock_queued_events(UnLockQueuedEventsRequest.t(), GRPC.Server.Stream.t()) ::
          UnLockQueuedEventsResponse.t()
  def unlock_queued_events(request, _stream) do
    destination =
      ER.Destinations.get_destination!(request.destination_id)

    # ensure we have the queued events server started. this is a noop if it is already started
    ER.Destinations.QueuedEvents.Server.factory(destination.id)

    try do
      events =
        ER.Destinations.QueuedEvents.Server.unlocked_queued_events(
          destination_id: request.destination_id,
          event_ids: request.event_ids
        )

      topic_name = destination.topic_name
      topic_identifier = destination.topic_identifier
      full_topic = ER.Events.Topic.build_topic(topic_name, topic_identifier)
      events = Enum.map(events, &build_event(&1, full_topic))

      UnLockQueuedEventsResponse.new(events: events)
    rescue
      e in ER.Filter.BadFieldError ->
        raise GRPC.RPCError,
          status: GRPC.Status.invalid_argument(),
          message: e.message
    end
  end

  defp build_event(event, topic) do
    occurred_at =
      if ER.empty?(event.occurred_at) do
        ""
      else
        DateTime.to_iso8601(event.occurred_at)
      end

    GrpcEvent.new(
      id: event.id,
      name: event.name,
      topic: topic,
      source: event.source,
      group_key: event.group_key,
      reference_key: event.reference_key,
      trace_key: event.trace_key,
      data: Event.data_json(event),
      context: event.context,
      occurred_at: occurred_at,
      offset: event.offset,
      user_id: event.user_id,
      anonymous_id: event.anonymous_id,
      errors: event.errors,
      data_schema: Event.data_schema_json(event),
      prev_id: event.prev_id
    )
  end
end
