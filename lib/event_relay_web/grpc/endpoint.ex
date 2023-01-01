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
    Subscription,
    DeleteSubscriptionResponse,
    DeleteSubscriptionRequest,
    ListSubscriptionsResponse,
    ListSubscriptionsRequest
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
      push: request.subscription.push,
      subscription_type: request.subscription.subscriptionType
    }

    subscription =
      case ER.Subscriptions.create_subscription(attrs) do
        {:ok, subscription} ->
          build_subscription(subscription)

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

  @spec delete_subscription(DeleteSubscriptionRequest.t(), GRPC.Server.Stream.t()) ::
          DeleteSubscriptionResponse.t()
  def delete_subscription(request, _stream) do
    try do
      db_subscription = ER.Subscriptions.get_subscription!(request.id)

      subscription =
        case ER.Subscriptions.delete_subscription(db_subscription) do
          {:ok, subscription} ->
            build_subscription(subscription)

          {:error, %Ecto.Changeset{} = changeset} ->
            raise GRPC.RPCError,
              status: GRPC.Status.invalid_argument(),
              message: ER.Ecto.changeset_errors_to_string(changeset)

          {:error, error} ->
            Logger.error("Failed to create subscription: #{inspect(error)}")
            raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
        end

      DeleteSubscriptionResponse.new(subscription: subscription)
    rescue
      _ in Ecto.NoResultsError ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "Subscription not found"
    end
  end

  @spec list_subscriptions(ListSubscriptionsRequest.t(), GRPC.Server.Stream.t()) ::
          ListSubscriptionsResponse.t()
  def list_subscriptions(request, _stream) do
    page = if request.page == 0, do: 1, else: request.page
    page_size = if request.pageSize == 0, do: 100, else: request.pageSize

    paginated_results = ER.Subscriptions.list_subscriptions(page: page, page_size: page_size)

    subscriptions = Enum.map(paginated_results.results, &build_subscription/1)

    ListSubscriptionsResponse.new(
      subscriptions: subscriptions,
      total_count: paginated_results.total_count,
      next_page: paginated_results.next_page,
      previous_page: paginated_results.previous_page,
      total_pages: paginated_results.total_pages
    )
  end

  defp build_subscription(subscription) do
    Subscription.new(
      id: subscription.id,
      name: subscription.name,
      topicName: subscription.topic_name,
      topicIdentifier: subscription.topic_identifier,
      push: subscription.push,
      config: subscription.config,
      subscriptionType: subscription.subscription_type
    )
  end
end

defmodule ERWeb.Grpc.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run(ERWeb.Grpc.EventRelay.Server)
end
