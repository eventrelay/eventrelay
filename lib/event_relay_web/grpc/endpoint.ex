defmodule ERWeb.Grpc.EventRelay.Server do
  use GRPC.Server, service: ERWeb.Grpc.Eventrelay.EventRelay.Service
  require Logger

  alias ERWeb.Grpc.Eventrelay.{
    PublishEventsRequest,
    PublishEventsResponse,
    ListTopicsResponse,
    Topic,
    CreateTopicResponse,
    CreateSubscriptionResponse,
    CreateSubscriptionRequest,
    Subscription
  }

  alias ERWeb.Grpc.Eventrelay.Event, as: GrpcEvent

  alias ER.Events.Event

  @spec publish_events(PublishEventsRequest.t(), GRPC.Server.Stream.t()) ::
          PublishEventsResponse.t()
  def publish_events(request, _stream) do
    events = request.events
    topic = request.topic
    {topic_name, topic_identifier} = ER.Events.Topic.parse_topic(topic)

    events =
      Enum.map(events, fn event ->
        case ER.Events.create_event_for_topic(%{
               name: Map.get(event, :name),
               source: Map.get(event, :source),
               data_json: Map.get(event, :data),
               context: Map.get(event, :context),
               occurred_at: Map.get(event, :occurredAt),
               user_id: Map.get(event, :userId),
               anonymous_id: Map.get(event, :anonymousId),
               topic_name: topic_name,
               topic_identifier: topic_identifier
             }) do
          {:ok, %Event{} = event} ->
            GrpcEvent.new(
              id: event.id,
              name: event.name,
              topic: topic,
              source: event.source,
              data: event.data_json,
              context: event.context,
              occurredAt: event.occurred_at,
              offset: event.offset,
              userId: event.user_id,
              anonymousId: event.anonymous_id,
              errors: event.errors
            )

          {:error, error} ->
            # TODO: provide a better error message
            Logger.error("Error creating event: #{inspect(error)}")
            nil
        end
      end)

    PublishEventsResponse.new(events: events)
  end

  @spec list_topics(ListTopicsRequest.t(), GRPC.Server.Stream.t()) :: ListTopicsResponse.t()
  def list_topics(_request, _stream) do
    topics =
      ER.Events.list_topics()
      |> Enum.map(fn topic ->
        Topic.new(
          id: topic.id,
          name: topic.name
        )
      end)

    ListTopicsResponse.new(topics: topics)
  end

  @spec create_topic(CreateTopicRequest.t(), GRPC.Server.Stream.t()) :: CreateTopicResponse.t()
  def create_topic(request, _stream) do
    topic =
      case ER.Events.create_topic_and_table(%{name: request.name}) do
        {:ok, topic} ->
          Topic.new(id: topic.id, name: topic.name)

        {:error, %Ecto.Changeset{} = changeset} ->
          case changeset.errors do
            [name: {"has already been taken", _}] ->
              raise GRPC.RPCError,
                status: GRPC.Status.already_exists(),
                message: "Topic already exists"

            _ ->
              raise GRPC.RPCError,
                status: GRPC.Status.invalid_argument(),
                message: ER.Ecto.changeset_errors_to_string(changeset)
          end

        {:error, error} ->
          Logger.error("Failed to create topic: #{inspect(error)}")
          raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
      end

    CreateTopicResponse.new(topic: topic)
  end

  @spec create_subscription(CreateSubscriptionRequest.t(), GRPC.Server.Stream.t()) ::
          CreateSubscriptionResponse.t()
  def create_subscription(request, _stream) do
    attrs = %{
      name: request.subscription.name,
      topic_name: request.subscription.topicName,
      topic_identifier: request.subscription.topicIdentifier,
      config: request.subscription.config,
      push: request.subscription.push
    }

    subscription =
      case ER.Subscriptions.create_subscription(attrs) do
        {:ok, subscription} ->
          Subscription.new(
            id: subscription.id,
            name: subscription.name,
            topicName: subscription.topic_name,
            topicIdentifier: subscription.topic_identifier,
            push: subscription.push,
            config: subscription.config
          )

        {:error, %Ecto.Changeset{} = changeset} ->
          case changeset.errors do
            [name: {"has already been taken", _}] ->
              raise GRPC.RPCError,
                status: GRPC.Status.already_exists(),
                message: "Subscription with that name already exists"

            _ ->
              raise GRPC.RPCError,
                status: GRPC.Status.invalid_argument(),
                message: ER.Ecto.changeset_errors_to_string(changeset)
          end

        {:error, error} ->
          Logger.error("Failed to create subscription: #{inspect(error)}")
          raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
      end

    CreateSubscriptionResponse.new(subscription: subscription)
  end
end

defmodule ERWeb.Grpc.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run(ERWeb.Grpc.EventRelay.Server)
end
