defmodule ERWeb.Grpc.EventRelay.Topics.ServerTest do
  use ER.DataCase

  alias ERWeb.Grpc.EventRelay.Topics.Server
  alias ER.Events

  alias ERWeb.Grpc.Eventrelay.{
    CreateTopicRequest,
    DeleteTopicRequest,
    ListTopicsRequest
  }

  describe "create_topic/2" do
    test "create a new topic" do
      request = %CreateTopicRequest{
        name: "audit_log",
        group_key: "tester"
      }

      result = Server.create_topic(request, nil)

      refute ER.Events.get_topic(result.topic.id) == nil
      assert result.topic.group_key == "tester"
    end
  end

  describe "delete_topic/2" do
    test "deletes a topic" do
      {:ok, topic} = Events.create_topic(%{name: "log"})

      request = %DeleteTopicRequest{
        id: topic.id
      }

      result = Server.delete_topic(request, nil)

      assert ER.Events.get_topic(result.topic.id) == nil
    end
  end

  describe "list_topics/2" do
    test "list topic" do
      {:ok, _topic} = Events.create_topic(%{name: "log"})
      {:ok, _topic} = Events.create_topic(%{name: "carts"})

      request = %ListTopicsRequest{}

      result = Server.list_topics(request, nil)
      assert Enum.count(result.topics) == 2
    end
  end
end
