defmodule ERWeb.Grpc.EventRelay.Destinations.Server do
  use GRPC.Server, service: ERWeb.Grpc.Eventrelay.Destinations.Service
  require Logger

  alias ERWeb.Grpc.Eventrelay.{
    CreateDestinationResponse,
    CreateDestinationRequest,
    Destination,
    DeleteDestinationResponse,
    DeleteDestinationRequest,
    ListDestinationsResponse,
    ListDestinationsRequest
  }

  @spec create_destination(CreateDestinationRequest.t(), GRPC.Server.Stream.t()) ::
          CreateDestinationResponse.t()
  def create_destination(request, _stream) do
    attrs = %{
      name: request.name,
      topic_name: request.topic_name,
      topic_identifier: request.topic_identifier,
      config: request.config,
      destination_type: request.destination_type,
      group_key: request.group_key
    }

    destination =
      case ER.Destinations.create_destination(attrs) do
        {:ok, destination} ->
          build_destination(destination)

        {:error, %Ecto.Changeset{} = changeset} ->
          case changeset.errors do
            [name: {"has already been taken", _}] ->
              raise GRPC.RPCError,
                status: GRPC.Status.already_exists(),
                message: "Destination with that name already exists"

            _ ->
              raise GRPC.RPCError,
                status: GRPC.Status.invalid_argument(),
                message: ER.Ecto.changeset_errors_to_string(changeset)
          end

        {:error, error} ->
          Logger.error("Failed to create destination: #{inspect(error)}")
          raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
      end

    CreateDestinationResponse.new(destination: destination)
  end

  @spec delete_destination(DeleteDestinationRequest.t(), GRPC.Server.Stream.t()) ::
          DeleteDestinationResponse.t()
  def delete_destination(request, _stream) do
    try do
      db_destination = ER.Destinations.get_destination!(request.id)

      destination =
        case ER.Destinations.delete_destination(db_destination) do
          {:ok, destination} ->
            build_destination(destination)

          {:error, %Ecto.Changeset{} = changeset} ->
            raise GRPC.RPCError,
              status: GRPC.Status.invalid_argument(),
              message: ER.Ecto.changeset_errors_to_string(changeset)

          {:error, error} ->
            Logger.error("Failed to create destination: #{inspect(error)}")
            raise GRPC.RPCError, status: GRPC.Status.unknown(), message: "Something went wrong"
        end

      DeleteDestinationResponse.new(destination: destination)
    rescue
      _ in Ecto.NoResultsError ->
        reraise GRPC.RPCError,
                [status: GRPC.Status.not_found(), message: "Destination not found"],
                __STACKTRACE__
    end
  end

  @spec list_destinations(ListDestinationsRequest.t(), GRPC.Server.Stream.t()) ::
          ListDestinationsResponse.t()
  def list_destinations(request, _stream) do
    page = if request.page == 0, do: 1, else: request.page
    page_size = if request.page_size == 0, do: 100, else: request.page_size

    paginated_results = ER.Destinations.list_destinations(page: page, page_size: page_size)

    destinations = Enum.map(paginated_results.results, &build_destination/1)

    ListDestinationsResponse.new(
      destinations: destinations,
      total_count: paginated_results.total_count,
      next_page: paginated_results.next_page,
      previous_page: paginated_results.previous_page,
      total_pages: paginated_results.total_pages
    )
  end

  defp build_destination(destination) do
    Destination.new(
      id: destination.id,
      name: destination.name,
      topic_name: destination.topic_name,
      topic_identifier: destination.topic_identifier,
      config: destination.config,
      destination_type: destination.destination_type,
      group_key: destination.group_key
    )
  end
end
