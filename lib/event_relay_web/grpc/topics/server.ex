defmodule ERWeb.Grpc.EventRelay.Topics.Server do
  @moduledoc """
  GRPC Server implementation for Topics Service
  """
  use GRPC.Server, service: ERWeb.Grpc.Eventrelay.Topics.Service
  require Logger

  alias ERWeb.Grpc.Eventrelay.{
    ListTopicsResponse,
    Topic,
    CreateTopicResponse
  }

  @spec list_topics(ListTopicsRequest.t(), GRPC.Server.Stream.t()) :: ListTopicsResponse.t()
  def list_topics(_request, _stream) do
    # TODO: Add pagination
    topics =
      ER.Events.list_topics()
      |> Enum.map(fn topic ->
        Topic.new(
          id: topic.id,
          name: topic.name,
          group_key: topic.group_key
        )
      end)

    ListTopicsResponse.new(topics: topics)
  end

  @spec create_topic(CreateTopicRequest.t(), GRPC.Server.Stream.t()) :: CreateTopicResponse.t()
  def create_topic(request, _stream) do
    topic =
      case ER.Events.create_topic(%{name: request.name, group_key: request.group_key}) do
        {:ok, topic} ->
          Topic.new(id: topic.id, name: topic.name, group_key: topic.group_key)

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

            reraise GRPC.RPCError,
                    [status: GRPC.Status.unknown(), message: "Something went wrong"],
                    __STACKTRACE__
        end
    end
  end
end
