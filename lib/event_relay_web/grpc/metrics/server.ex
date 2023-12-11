defmodule ERWeb.Grpc.EventRelay.Metrics.Server do
  use GRPC.Server, service: ERWeb.Grpc.Eventrelay.Metrics.Service
  require Logger

  alias ERWeb.Grpc.Eventrelay.{
    GetMetricValueRequest,
    GetMetricValueResponse,
    CreateMetricResponse,
    CreateMetricRequest,
    Metric,
    DeleteMetricRequest,
    DeleteMetricResponse,
    ListMetricsRequest,
    ListMetricsResponse
  }

  import ER.Enum

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
          value = to_string(ER.Metrics.get_value_for_metric(metric))
          GetMetricValueResponse.new(value: value)
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
      type: to_grpc_enum(metric.type),
      query: metric.query
    )
  end

  @spec list_metrics(ListMetricsRequest.t(), GRPC.Server.Stream.t()) ::
          ListMetricsResponse.t()
  def list_metrics(request, _stream) do
    topic = request.topic
    query = request.query
    {topic_name, topic_identifier} = ER.Events.Topic.parse_topic(topic)

    page = if request.page == 0, do: 1, else: request.page
    page_size = if request.page_size == 0, do: 100, else: request.page_size
    # TODO: add logic for max page size and make it configurable

    paginated_results =
      ER.Metrics.list_metrics(
        topic_name: topic_name,
        topic_identifier: topic_identifier,
        query: query,
        page: page,
        page_size: page_size
      )

    metrics = Enum.map(paginated_results.results, &build_metric/1)

    ListMetricsResponse.new(
      metrics: metrics,
      total_count: paginated_results.total_count,
      next_page: paginated_results.next_page,
      previous_page: paginated_results.previous_page,
      total_pages: paginated_results.total_pages
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
      query: request.metric.query
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
end
