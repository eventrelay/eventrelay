defmodule ERWeb.Grpc.EventRelay.Subscriptions.Server do
  use GRPC.Server, service: ERWeb.Grpc.Eventrelay.Subscriptions.Service
  require Logger

  alias ERWeb.Grpc.Eventrelay.{
    CreateSubscriptionResponse,
    CreateSubscriptionRequest,
    Subscription,
    DeleteSubscriptionResponse,
    DeleteSubscriptionRequest,
    ListSubscriptionsResponse,
    ListSubscriptionsRequest
  }

  @spec create_subscription(CreateSubscriptionRequest.t(), GRPC.Server.Stream.t()) ::
          CreateSubscriptionResponse.t()
  def create_subscription(request, _stream) do
    attrs = %{
      name: request.subscription.name,
      topic_name: request.subscription.topic_name,
      topic_identifier: request.subscription.topic_identifier,
      config: request.subscription.config,
      subscription_type: request.subscription.subscription_type,
      group_key: request.subscription.group_key
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
      config: subscription.config,
      subscription_type: subscription.subscription_type,
      group_key: subscription.group_key
    )
  end
end
