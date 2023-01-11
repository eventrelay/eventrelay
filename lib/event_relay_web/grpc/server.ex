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
    ListSubscriptionsRequest,
    PullEventsRequest,
    PullEventsResponse,
    CreateApiKeyRequest,
    CreateApiKeyResponse,
    ApiKey,
    RevokeApiKeyRequest,
    RevokeApiKeyResponse,
    AddSubscriptionToApiKeyRequest,
    AddSubscriptionToApiKeyResponse,
    DeleteSubscriptionFromApiKeyRequest,
    DeleteSubscriptionFromApiKeyResponse,
    CreateJWTRequest,
    CreateJWTResponse
  }

  alias ERWeb.Grpc.Eventrelay.Event, as: GrpcEvent

  alias ER.Events.Event

  @spec create_jwt(CreateJWTRequest.t(), GRPC.Server.Stream.t()) :: CreateJWTResponse.t()
  def create_jwt(request, _stream) do
    claims =
      unless ER.empty?(request.expiration) do
        %{
          exp: request.expiration
        }
      else
        %{}
      end

    case ER.JWT.Token.build(request.api_key, claims) do
      {:ok, jwt} ->
        CreateJWTResponse.new(jwt: jwt)

      {:error, reason} ->
        raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
    end
  end

  @spec publish_events(PublishEventsRequest.t(), GRPC.Server.Stream.t()) ::
          PublishEventsResponse.t()
  def publish_events(request, _stream) do
    events = request.events
    topic = request.topic
    {topic_name, topic_identifier} = ER.Events.Topic.parse_topic(topic)
    durable = if ER.boolean?(request.durable), do: false, else: request.durable

    events =
      Enum.map(events, fn event ->
        case ER.Events.produce_event_for_topic(%{
               name: Map.get(event, :name),
               source: Map.get(event, :source),
               data_json: Map.get(event, :data),
               context: Map.get(event, :context),
               occurred_at: Map.get(event, :occurredAt),
               user_id: Map.get(event, :userId),
               anonymous_id: Map.get(event, :anonymousId),
               durable: durable,
               topic_name: topic_name,
               topic_identifier: topic_identifier
             }) do
          {:ok, %Event{} = event} ->
            build_event(event, topic)

          {:error, error} ->
            # TODO: provide a better error message
            Logger.error("Error creating event: #{inspect(error)}")
            nil
        end
      end)

    PublishEventsResponse.new(events: events)
  end

  @spec pull_events(PullEventsRequest.t(), GRPC.Server.Stream.t()) :: PullEventsResponse.t()
  def pull_events(request, _stream) do
    topic = request.topic
    {topic_name, topic_identifier} = ER.Events.Topic.parse_topic(topic)
    offset = if request.offset == 0, do: nil, else: request.offset
    batch_size = if request.batchSize == 0, do: 100, else: request.batchSize
    batch_size = if batch_size > 1000, do: 100, else: batch_size

    batched_results =
      ER.Events.list_events_for_topic(
        offset: offset,
        batch_size: batch_size,
        topic_name: topic_name,
        topic_identifier: topic_identifier
      )

    events = Enum.map(batched_results.results, &build_event(&1, topic))

    PullEventsResponse.new(
      events: events,
      nextOffset: batched_results.next_offset,
      previousOffset: batched_results.previous_offset,
      totalCount: batched_results.total_count,
      totalBatches: batched_results.total_batches
    )
  end

  defp build_event(event, topic) do
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
  end

  @spec list_topics(ListTopicsRequest.t(), GRPC.Server.Stream.t()) :: ListTopicsResponse.t()
  def list_topics(request, _stream) do
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
      case ER.Events.create_topic(%{name: request.name}) do
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

  @spec delete_topic(DeleteTopicRequest.t(), GRPC.Server.Stream.t()) :: DeleteTopicResponse.t()
  def delete_topic(request, _stream) do
    case ER.Events.get_topic(request.id) do
      nil ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "Topic not found"

      topic ->
        try do
          case ER.Events.delete_topic(topic) do
            {:ok, topic} ->
              CreateTopicResponse.new(topic: Topic.new(id: topic.id, name: topic.name))

            {:error, %Ecto.Changeset{} = changeset} ->
              raise GRPC.RPCError,
                status: GRPC.Status.invalid_argument(),
                message: ER.Ecto.changeset_errors_to_string(changeset)

            {:error, error} ->
              Logger.error("Failed to delete topic: #{inspect(error)}")

              raise GRPC.RPCError,
                status: GRPC.Status.unknown(),
                message: "Something went wrong"
          end
        rescue
          error ->
            Logger.error("Failed to delete topic: #{inspect(error)}")
            raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
        end
    end
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
      totalCount: paginated_results.total_count,
      nextPage: paginated_results.next_page,
      previousPage: paginated_results.previous_page,
      totalPages: paginated_results.total_pages
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

  ## ApiKeys

  @spec create_api_key(CreateApiKeyRequest.t(), GRPC.Server.Stream.t()) ::
          CreateApiKeyResponse.t()
  def create_api_key(request, _stream) do
    api_key = ER.Accounts.ApiKey.build(request.type, :active)

    api_key =
      case ER.Accounts.create_api_key(api_key) do
        {:ok, api_key} ->
          build_api_key(api_key)

        {:error, %Ecto.Changeset{} = changeset} ->
          case changeset.errors do
            [key_secret_status_type_unique: {"has already been taken", _}] ->
              raise GRPC.RPCError,
                status: GRPC.Status.already_exists(),
                message: "ApiKey already exists"

            _ ->
              raise GRPC.RPCError,
                status: GRPC.Status.invalid_argument(),
                message: ER.Ecto.changeset_errors_to_string(changeset)
          end

        {:error, error} ->
          Logger.error("Failed to create topic: #{inspect(error)}")
          raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
      end

    CreateApiKeyResponse.new(api_key: api_key)
  end

  @spec revoke_api_key(RevokeApiKeyRequest.t(), GRPC.Server.Stream.t()) ::
          RevokeApiKeyResponse.t()
  def revoke_api_key(request, _stream) do
    case ER.Accounts.get_api_key(request.id) do
      nil ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "ApiKey not found"

      api_key ->
        try do
          case ER.Accounts.update_api_key(api_key, %{status: :revoked}) do
            {:ok, topic} ->
              RevokeApiKeyResponse.new(api_key: build_api_key(api_key))

            {:error, %Ecto.Changeset{} = changeset} ->
              raise GRPC.RPCError,
                status: GRPC.Status.invalid_argument(),
                message: ER.Ecto.changeset_errors_to_string(changeset)

            {:error, error} ->
              Logger.error("Failed to revoke api key: #{inspect(error)}")

              raise GRPC.RPCError,
                status: GRPC.Status.unknown(),
                message: "Something went wrong"
          end
        rescue
          error ->
            Logger.error("Failed to delete topic: #{inspect(error)}")
            raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
        end
    end
  end

  @spec add_subscription_to_api_key_request(
          AddSubscriptionToApiKeyRequest.t(),
          GRPC.Server.Stream.t()
        ) ::
          AddApiKeyToSubscriptionResponse.t()
  def add_subscription_to_api_key_request(request, _stream) do
    with {:api_key, api_key} when not is_nil(api_key) <-
           {:api_key, ER.Accounts.get_api_key(request.apiKeyId)},
         {:subscription, subscription} when not is_nil(subscription) <-
           {:subscription, ER.Subscriptions.get_subscription(request.subscriptionId)} do
      try do
        case ER.Accounts.create_api_key_subscription(api_key, subscription) do
          {:ok, api_key_subscription} ->
            AddSubscriptionToApiKeyResponse.new(
              apiKeyId: api_key_subscription.api_key_id,
              subscriptionId: api_key_subscription.subscription_id
            )

          {:error, %Ecto.Changeset{} = changeset} ->
            raise GRPC.RPCError,
              status: GRPC.Status.invalid_argument(),
              message: ER.Ecto.changeset_errors_to_string(changeset)

          {:error, error} ->
            Logger.error("Failed to create api key subscription: #{inspect(error)}")

            raise GRPC.RPCError,
              status: GRPC.Status.unknown(),
              message: "Something went wrong"
        end
      rescue
        error ->
          Logger.error("Failed to create api key subscription: #{inspect(error)}")
          raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
      end
    else
      {:api_key, nil} ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "ApiKey not found"

      {:subscription, nil} ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "Subscription not found"
    end
  end

  @spec delete_subscription_from_api_key(
          DeleteSubscriptionFromApiKeyRequest.t(),
          GRPC.Server.Stream.t()
        ) ::
          DeleteSubscriptionFromApiKeyResponse.t()
  def delete_subscription_from_api_key(request, _stream) do
    with {:api_key, api_key} when not is_nil(api_key) <-
           {:api_key, ER.Accounts.get_api_key(request.apiKeyId)},
         {:subscription, subscription} when not is_nil(subscription) <-
           {:subscription, ER.Subscriptions.get_subscription(request.subscriptionId)},
         {:api_key_subscription, api_key_subscription} when not is_nil(api_key_subscription) <-
           {:api_key_subscription, ER.Accounts.get_api_key_subscription(api_key, subscription)} do
      try do
        case ER.Accounts.delete_api_key_subscription(api_key_subscription) do
          {:ok, api_key_subscription} ->
            DeleteSubscriptionFromApiKeyResponse.new(
              apiKeyId: api_key_subscription.api_key_id,
              subscriptionId: api_key_subscription.subscription_id
            )

          {:error, %Ecto.Changeset{} = changeset} ->
            raise GRPC.RPCError,
              status: GRPC.Status.invalid_argument(),
              message: ER.Ecto.changeset_errors_to_string(changeset)

          {:error, error} ->
            Logger.error("Failed to delete api key subscription: #{inspect(error)}")

            raise GRPC.RPCError,
              status: GRPC.Status.unknown(),
              message: "Something went wrong"
        end
      rescue
        error ->
          Logger.error("Failed to delete api key subscription: #{inspect(error)}")
          raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
      end
    else
      {:api_key, nil} ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "ApiKey not found"

      {:subscription, nil} ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "Subscription not found"

      {:api_key_subscription, nil} ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "ApiKeySubscription not found"
    end
  end

  def build_api_key(api_key) do
    ApiKey.new(
      id: api_key.id,
      key: api_key.key,
      secret: api_key.secret,
      type: api_key.type,
      status: api_key.status
    )
  end
end
