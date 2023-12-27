defmodule ERWeb.Grpc.EventRelay.ApiKeys.ServerTest do
  use ER.DataCase

  import ER.Factory
  alias ERWeb.Grpc.EventRelay.ApiKeys.Server
  alias Repo

  alias ERWeb.Grpc.Eventrelay.{
    CreateApiKeyRequest,
    RevokeApiKeyRequest,
    AddDestinationsToApiKeyRequest,
    DeleteDestinationsFromApiKeyRequest,
    AddTopicsToApiKeyRequest,
    DeleteTopicsFromApiKeyRequest
  }

  describe "create_api_key/2" do
    test "create a new Api Key" do
      request = %CreateApiKeyRequest{
        name: "Test Consumer",
        group_key: "test_group",
        type: :CONSUMER,
        tls_hostname: "localhost"
      }

      result = Server.create_api_key(request, nil)

      new_api_key = result.api_key

      assert new_api_key.name == request.name
      refute new_api_key.id == nil
      assert new_api_key.type == :CONSUMER
      assert new_api_key.status == :ACTIVE
      assert new_api_key.tls_hostname == "localhost"
      assert new_api_key.group_key == "test_group"
    end
  end

  describe "revoke_api_key/2" do
    test "revoke an Api Key" do
      api_key = insert(:api_key)

      assert api_key.status == :active

      request = %RevokeApiKeyRequest{
        id: api_key.id
      }

      result = Server.revoke_api_key(request, nil)

      revoked_api_key = result.api_key

      assert revoked_api_key.status == :REVOKED
    end

    test "return error is api key is already revoked" do
      api_key = insert(:api_key, status: :revoked)

      assert api_key.status == :revoked

      request = %RevokeApiKeyRequest{
        id: api_key.id
      }

      assert_raise GRPC.RPCError, "ApiKey is already revoked", fn ->
        Server.revoke_api_key(request, nil)
      end
    end
  end

  describe "add_destinations_to_api_key/2" do
    test "raises an error because api key is a producer" do
      api_key = insert(:api_key, type: :producer)
      destination = insert(:destination)

      request = %AddDestinationsToApiKeyRequest{
        id: api_key.id,
        destination_ids: [destination.id]
      }

      assert_raise GRPC.RPCError, "ApiKey is not of type consumer or producer/consumer", fn ->
        Server.add_destinations_to_api_key(request, nil)
      end
    end

    test "raises an error because api key is a admin" do
      api_key = insert(:api_key, type: :admin)
      destination = insert(:destination)

      request = %AddDestinationsToApiKeyRequest{
        id: api_key.id,
        destination_ids: [destination.id]
      }

      assert_raise GRPC.RPCError, "ApiKey is not of type consumer or producer/consumer", fn ->
        Server.add_destinations_to_api_key(request, nil)
      end
    end

    test "add destinations to an Api Key" do
      api_key = insert(:api_key)
      destination = insert(:destination)

      request = %AddDestinationsToApiKeyRequest{
        id: api_key.id,
        destination_ids: [destination.id]
      }

      result = Server.add_destinations_to_api_key(request, nil)

      assert result.destination_ids == [destination.id]

      api_key = Repo.reload(api_key) |> Repo.preload(:destinations)

      assert Enum.map(api_key.destinations, & &1.id) == [destination.id]
    end
  end

  describe "delete_destinations_to_api_key/2" do
    test "delete destinations to an Api Key" do
      destination = insert(:destination)
      api_key = insert(:api_key, destinations: [destination])

      request = %DeleteDestinationsFromApiKeyRequest{
        id: api_key.id,
        destination_ids: [destination.id]
      }

      result = Server.delete_destinations_from_api_key(request, nil)

      assert result.destination_ids == [destination.id]

      api_key = Repo.reload(api_key) |> Repo.preload(:destinations)

      assert api_key.destinations == []
    end
  end

  describe "add_topics_to_api_key/2" do
    test "add topics to an Api Key" do
      api_key = insert(:api_key, type: :producer)
      topic = insert(:topic)

      request = %AddTopicsToApiKeyRequest{
        id: api_key.id,
        topic_names: [topic.name]
      }

      result = Server.add_topics_to_api_key(request, nil)

      assert result.topic_names == [topic.name]

      api_key = Repo.reload(api_key) |> Repo.preload(:topics)

      assert Enum.map(api_key.topics, & &1.id) == [topic.id]
    end

    test "raises an error because api key is a admin" do
      api_key = insert(:api_key, type: :admin)
      topic = insert(:topic)

      request = %AddTopicsToApiKeyRequest{
        id: api_key.id,
        topic_names: [topic.name]
      }

      assert_raise GRPC.RPCError, "ApiKey is not of type producer or producer/consumer", fn ->
        Server.add_topics_to_api_key(request, nil)
      end
    end

    test "raises an error because api key is a consumer" do
      api_key = insert(:api_key, type: :consumer)
      topic = insert(:topic)

      request = %AddTopicsToApiKeyRequest{
        id: api_key.id,
        topic_names: [topic.name]
      }

      assert_raise GRPC.RPCError, "ApiKey is not of type producer or producer/consumer", fn ->
        Server.add_topics_to_api_key(request, nil)
      end
    end
  end

  describe "delete_topics_to_api_key/2" do
    test "delete topics to an Api Key" do
      topic = insert(:topic)
      api_key = insert(:api_key, topics: [topic], type: :producer)

      request = %DeleteTopicsFromApiKeyRequest{
        id: api_key.id,
        topic_names: [topic.name]
      }

      result = Server.delete_topics_from_api_key(request, nil)

      assert result.topic_names == [topic.name]

      api_key = Repo.reload(api_key) |> Repo.preload(:topics)

      assert api_key.topics == []
    end
  end
end
