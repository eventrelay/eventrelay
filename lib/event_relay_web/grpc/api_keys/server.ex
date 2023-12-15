defmodule ERWeb.Grpc.EventRelay.ApiKeys.Server do
  use GRPC.Server, service: ERWeb.Grpc.Eventrelay.ApiKeys.Service
  require Logger

  alias ERWeb.Grpc.Eventrelay.{
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
    DeleteTopicsFromApiKeyResponse
  }

  alias ER.Repo
  import ER.Enum

  @spec create_api_key(CreateApiKeyRequest.t(), GRPC.Server.Stream.t()) ::
          CreateApiKeyResponse.t()
  def create_api_key(request, _stream) do
    attrs = %{
      name: request.name,
      group_key: request.group_key,
      type: from_grpc_enum(request.type),
      tls_hostname: request.tls_hostname,
      status: :active
    }

    api_key =
      case ER.Accounts.create_api_key(attrs) do
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
        end)
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

  def build_api_key(api_key) do
    ApiKey.new(
      id: api_key.id,
      key: api_key.key,
      secret: api_key.secret,
      type: to_grpc_enum(api_key.type),
      status: to_grpc_enum(api_key.status),
      group_key: api_key.group_key
    )
  end
end
