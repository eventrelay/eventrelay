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
    EventFilter,
    CreateApiKeyRequest,
    CreateApiKeyResponse,
    ApiKey,
    RevokeApiKeyRequest,
    RevokeApiKeyResponse,
    AddSubscriptionsToApiKeyRequest,
    AddSubscriptionsToApiKeyResponse,
    DeleteSubscriptionsFromApiKeyRequest,
    DeleteSubscriptionsFromApiKeyResponse,
    AddTopicsToApiKeyResponse,
    AddTopicsToApiKeyRequest,
    DeleteTopicsFromApiKeyRequest,
    DeleteTopicsFromApiKeyResponse,
    CreateJWTRequest,
    CreateJWTResponse,
    GetMetricValueRequest,
    GetMetricValueResponse,
    CreateMetricResponse,
    CreateMetricRequest,
    Metric,
    DeleteMetricRequest,
    DeleteMetricResponse
  }

  alias ERWeb.Grpc.Eventrelay.Event, as: GrpcEvent

  alias ER.Events.Event
  alias ER.Repo
  import ERWeb.Grpc.Enums, only: [to_grpc_enum: 1, from_grpc_enum: 1]

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

      {:error, _reason} ->
        raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
    end
  end

  @spec publish_events(PublishEventsRequest.t(), GRPC.Server.Stream.t()) ::
          PublishEventsResponse.t()
  def publish_events(request, _stream) do
    events = request.events
    topic = request.topic
    {topic_name, topic_identifier} = ER.Events.Topic.parse_topic(topic)
    durable = unless ER.boolean?(request.durable), do: false, else: request.durable

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

    batched_results =
      ER.Events.list_events_for_topic(
        offset: offset,
        batch_size: batch_size,
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        filters: request.filters
      )

    events = Enum.map(batched_results.results, &build_event(&1, topic))

    PullEventsResponse.new(
      events: events,
      next_offset: batched_results.next_offset,
      previous_offset: batched_results.previous_offset,
      total_count: batched_results.total_count,
      total_batches: batched_results.total_batches
    )
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
      errors: event.errors
    )
  end

  @spec list_topics(ListTopicsRequest.t(), GRPC.Server.Stream.t()) :: ListTopicsResponse.t()
  def list_topics(_request, _stream) do
    # TODO: Add pagination
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
      topic_name: request.subscription.topic_name,
      topic_identifier: request.subscription.topic_identifier,
      config: request.subscription.config,
      push: request.subscription.push,
      subscription_type: request.subscription.subscription_type
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
    page_size = if request.page_size == 0, do: 100, else: request.page_size

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
      topic_name: subscription.topic_name,
      topic_identifier: subscription.topic_identifier,
      push: subscription.push,
      config: subscription.config,
      subscription_type: subscription.subscription_type
    )
  end

  ## ApiKeys

  @spec create_api_key(CreateApiKeyRequest.t(), GRPC.Server.Stream.t()) ::
          CreateApiKeyResponse.t()
  def create_api_key(request, _stream) do
    api_key = ER.Accounts.ApiKey.build(from_grpc_enum(request.type), :active)

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
        if api_key.status == :revoked do
          raise GRPC.RPCError,
            status: GRPC.Status.failed_precondition(),
            message: "ApiKey is already revoked"
        end

        try do
          case ER.Accounts.update_api_key(api_key, %{status: :revoked}) do
            {:ok, api_key} ->
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

  @spec add_subscriptions_to_api_key(
          AddSubscriptionsToApiKeyRequest.t(),
          GRPC.Server.Stream.t()
        ) ::
          AddApiKeyToSubscriptionsResponse.t()
  def add_subscriptions_to_api_key(request, _stream) do
    with {:api_key, api_key} when not is_nil(api_key) <-
           {:api_key, ER.Accounts.get_api_key(request.id)},
         {:subscriptions, subscriptions} when not is_nil(subscriptions) <-
           {:subscriptions, ER.Subscriptions.list_subscriptions(ids: request.subscription_ids)} do
      if api_key.status == :revoked do
        raise GRPC.RPCError,
          status: GRPC.Status.failed_precondition(),
          message: "ApiKey is revoked"
      end

      if api_key.type in [:admin, :producer] do
        raise GRPC.RPCError,
          status: GRPC.Status.failed_precondition(),
          message: "ApiKey is not of type consumer"
      end

      try do
        Repo.transaction(fn ->
          Enum.map(subscriptions, fn subscription ->
            case ER.Accounts.create_api_key_subscription(api_key, subscription) do
              {:ok, api_key_subscription} ->
                api_key_subscription.subscription_id

              {:error, %Ecto.Changeset{} = changeset} ->
                raise GRPC.RPCError,
                  status: GRPC.Status.invalid_argument(),
                  message: ER.Ecto.changeset_errors_to_string(changeset)

              {:error, error} ->
                Logger.error("Failed to create api key subscription: #{inspect(error)}")
                nil
            end
          end)
          |> Enum.reject(&is_nil/1)
        end)
        |> case do
          {:ok, api_key_subscription_ids} ->
            AddSubscriptionsToApiKeyResponse.new(
              id: api_key.id,
              subscription_ids: api_key_subscription_ids
            )

          {:error, error} ->
            Logger.error("Failed to add subscriptions to api key: #{inspect(error)}")

            raise GRPC.RPCError,
              status: GRPC.Status.unknown(),
              message: "Something went wrong"
        end
      rescue
        error ->
          case error do
            %GRPC.RPCError{} ->
              raise error

            _ ->
              Logger.error("Failed to add subscriptions to api key: #{inspect(error)}")

              raise GRPC.RPCError,
                status: GRPC.Status.unknown(),
                message: "Something went wrong"
          end
      end
    else
      {:api_key, nil} ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "ApiKey not found"

      {:subscriptions, []} ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "Subscriptions not found"
    end
  end

  @spec delete_subscriptions_from_api_key(
          DeleteSubscriptionsFromApiKeyRequest.t(),
          GRPC.Server.Stream.t()
        ) ::
          DeleteSubscriptionsFromApiKeyResponse.t()
  def delete_subscriptions_from_api_key(request, _stream) do
    with {:api_key, api_key} when not is_nil(api_key) <-
           {:api_key, ER.Accounts.get_api_key(request.id)},
         {:subscriptions, subscriptions} when not is_nil(subscriptions) <-
           {:subscriptions, ER.Subscriptions.list_subscriptions(ids: request.subscription_ids)} do
      try do
        Repo.transaction(fn ->
          Enum.map(subscriptions, fn subscription ->
            api_key_subscription = ER.Accounts.get_api_key_subscription(api_key, subscription)

            case ER.Accounts.delete_api_key_subscription(api_key_subscription) do
              {:ok, api_key_subscription} ->
                api_key_subscription.subscription_id

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
          end)
          |> Enum.reject(&is_nil/1)
          |> IO.inspect(label: "api_key_subscriptions")
        end)
        |> IO.inspect(label: "transaction")
        |> case do
          {:ok, api_key_subscription_ids} ->
            DeleteSubscriptionsFromApiKeyResponse.new(
              id: api_key.id,
              subscription_ids: api_key_subscription_ids
            )

          {:error, error} ->
            Logger.error("Failed to delete subscriptions to api key: #{inspect(error)}")

            raise GRPC.RPCError,
              status: GRPC.Status.unknown(),
              message: "Something went wrong"
        end
      rescue
        error ->
          case error do
            %GRPC.RPCError{} ->
              raise error

            _ ->
              Logger.error("Failed to delete api key subscription: #{inspect(error)}")
              raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
          end
      end
    else
      {:api_key, nil} ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "ApiKey not found"
    end
  end

  @spec add_topics_to_api_key(
          AddTopicsToApiKeyRequest.t(),
          GRPC.Server.Stream.t()
        ) ::
          AddTopicsToApiKeyRequest.t()
  def add_topics_to_api_key(request, _stream) do
    with {:api_key, api_key} when not is_nil(api_key) <-
           {:api_key, ER.Accounts.get_api_key(request.id)},
         {:topics, topics} when is_list(topics) <-
           {:topics, ER.Events.list_topics(names: request.topic_names)} do
      if api_key.status == :revoked do
        raise GRPC.RPCError,
          status: GRPC.Status.failed_precondition(),
          message: "ApiKey is revoked"
      end

      if api_key.type in [:admin, :consumer] do
        raise GRPC.RPCError,
          status: GRPC.Status.failed_precondition(),
          message: "ApiKey is not of type producer"
      end

      try do
        Repo.transaction(fn ->
          Enum.map(topics, fn topic ->
            case ER.Accounts.create_api_key_topic(api_key, topic) do
              {:ok, api_key_topic} ->
                api_key_topic.topic_name

              {:error, %Ecto.Changeset{} = changeset} ->
                raise GRPC.RPCError,
                  status: GRPC.Status.invalid_argument(),
                  message: ER.Ecto.changeset_errors_to_string(changeset)

              {:error, error} ->
                Logger.error("Failed to create api key topic: #{inspect(error)}")
                nil
            end
          end)
          |> Enum.reject(&is_nil/1)
        end)
        |> case do
          {:ok, api_key_topic_names} ->
            AddTopicsToApiKeyResponse.new(
              id: api_key.id,
              topic_names: api_key_topic_names
            )

          {:error, error} ->
            Logger.error("Failed to add topics to api key: #{inspect(error)}")

            raise GRPC.RPCError,
              status: GRPC.Status.unknown(),
              message: "Something went wrong"
        end
      rescue
        error ->
          case error do
            %GRPC.RPCError{} ->
              raise error

            _ ->
              Logger.error("Failed to add topics to api key: #{inspect(error)}")

              raise GRPC.RPCError,
                status: GRPC.Status.unknown(),
                message: "Something went wrong"
          end
      end
    else
      {:api_key, nil} ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "ApiKey not found"

      {:topics, []} ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "Topics not found"
    end
  end

  @spec delete_topics_from_api_key(
          DeleteTopicsFromApiKeyRequest.t(),
          GRPC.Server.Stream.t()
        ) ::
          DeleteTopicsFromApiKeyResponse.t()
  def delete_topics_from_api_key(request, _stream) do
    with {:api_key, api_key} when not is_nil(api_key) <-
           {:api_key, ER.Accounts.get_api_key(request.id)},
         {:topics, topics} when is_list(topics) <-
           {:topics, ER.Events.list_topics(names: request.topic_names)} do
      try do
        Repo.transaction(fn ->
          Enum.map(topics, fn topic ->
            api_key_topic = ER.Accounts.get_api_key_topic(api_key, topic)

            case ER.Accounts.delete_api_key_topic(api_key_topic) do
              {:ok, api_key_topic} ->
                api_key_topic.topic_name

              {:error, %Ecto.Changeset{} = changeset} ->
                raise GRPC.RPCError,
                  status: GRPC.Status.invalid_argument(),
                  message: ER.Ecto.changeset_errors_to_string(changeset)

              {:error, error} ->
                Logger.error("Failed to delete api key topic: #{inspect(error)}")

                raise GRPC.RPCError,
                  status: GRPC.Status.unknown(),
                  message: "Something went wrong"
            end
          end)
          |> Enum.reject(&is_nil/1)
        end)
        |> case do
          {:ok, api_key_topic_names} ->
            DeleteTopicsFromApiKeyResponse.new(
              id: api_key.id,
              topic_names: api_key_topic_names
            )

          {:error, error} ->
            Logger.error("Failed to delete topic to api key: #{inspect(error)}")

            raise GRPC.RPCError,
              status: GRPC.Status.unknown(),
              message: "Something went wrong"
        end
      rescue
        error ->
          case error do
            %GRPC.RPCError{} ->
              raise error

            _ ->
              Logger.error("Failed to delete api key topic: #{inspect(error)}")
              raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
          end
      end
    else
      {:api_key, nil} ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "ApiKey not found"
    end
  end

  @spec get_metric_value(
          GetMetricValueRequest.t(),
          GRPC.Server.Stream.t()
        ) ::
          GetMetricValueResponse.t()
  def get_metric_value(request, _stream) do
    case ER.Metrics.get_metric(request.id) do
      nil ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "Metric not found"

      metric ->
        try do
          GetMetricValueResponse.new(value: ER.Metrics.get_value_for_metric(metric))
        rescue
          error ->
            Logger.error("Failed to delete topic: #{inspect(error)}")
            raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
        end
    end
  end

  defp build_metric(metric) do
    Metric.new(
      id: metric.id,
      name: metric.name,
      field_path: metric.field_path,
      topic_name: metric.topic_name,
      topic_identifier: metric.topic_identifier,
      type: metric.type,
      filters: Enum.map(metric.filters, &build_event_filter/1)
    )
  end

  defp build_event_filter(filter) do
    EventFilter.new(
      field: filter.field,
      field_path: filter.field_path,
      comparison: filter.comparison,
      value: filter.value
    )
  end

  @spec create_metric(CreateMetricRequest.t(), GRPC.Server.Stream.t()) ::
          CreateMetricResponse.t()
  def create_metric(request, _stream) do
    attrs = %{
      name: request.metric.name,
      field_path: request.metric.field_path,
      topic_name: request.metric.topic_name,
      topic_identifier: request.metric.topic_identifier,
      type: from_grpc_enum(request.metric.type),
      filters: Enum.map(request.metric.filters, &Map.from_struct/1)
    }

    metric =
      case ER.Metrics.create_metric(attrs) do
        {:ok, metric} ->
          build_metric(metric)

        {:error, %Ecto.Changeset{} = changeset} ->
          case changeset.errors do
            # [name: {"has already been taken", _}] ->
            #   raise GRPC.RPCError,
            #     status: GRPC.Status.already_exists(),
            #     message: "Metric with that name already exists"

            _ ->
              raise GRPC.RPCError,
                status: GRPC.Status.invalid_argument(),
                message: ER.Ecto.changeset_errors_to_string(changeset)
          end

        {:error, error} ->
          Logger.error("Failed to create metric: #{inspect(error)}")
          raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
      end

    CreateMetricResponse.new(metric: metric)
  end

  @spec delete_metric(DeleteMetricRequest.t(), GRPC.Server.Stream.t()) ::
          DeleteMetricResponse.t()
  def delete_metric(request, _stream) do
    case ER.Metrics.get_metric(request.id) do
      nil ->
        raise GRPC.RPCError,
          status: GRPC.Status.not_found(),
          message: "Metric not found"

      db_metric ->
        metric =
          case ER.Metrics.delete_metric(db_metric) do
            {:ok, metric} ->
              build_metric(metric)

            {:error, %Ecto.Changeset{} = changeset} ->
              raise GRPC.RPCError,
                status: GRPC.Status.invalid_argument(),
                message: ER.Ecto.changeset_errors_to_string(changeset)

            {:error, error} ->
              Logger.error("Failed to delete metric: #{inspect(error)}")
              raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
          end

        DeleteMetricResponse.new(metric: metric)
    end
  end

  def build_api_key(api_key) do
    ApiKey.new(
      id: api_key.id,
      key: api_key.key,
      secret: api_key.secret,
      type: to_grpc_enum(api_key.type),
      status: to_grpc_enum(api_key.status)
    )
  end
end
