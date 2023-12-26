defmodule ER.Accounts.ApiKeyTest do
  use ER.DataCase

  import ER.Factory
  alias ER.Repo
  alias ER.Accounts.ApiKey

  describe "allowed_topic?/2" do
    setup do
      {:ok, topic} = ER.Events.create_topic(%{name: "log"})

      {:ok, topic: topic}
    end

    test "return true when a topic is allowed", %{topic: topic} do
      api_key = insert(:api_key)

      ER.Accounts.create_api_key_topic(api_key, topic)

      api_key = Repo.preload(api_key, :topics)

      assert ApiKey.allowed_topic?(api_key, topic.name) == true
    end

    test "return false when a topic is not allowed", %{topic: topic} do
      api_key = insert(:api_key)

      api_key = Repo.preload(api_key, :topics)

      assert ApiKey.allowed_topic?(api_key, topic.name) == false
    end
  end

  describe "allowed_destination?/2" do
    setup do
      {:ok, topic} = ER.Events.create_topic(%{name: "log"})
      {:ok, topic: topic}
    end

    test "return true when a topic is allowed", %{topic: topic} do
      api_key = insert(:api_key)
      destination = insert(:destination, topic: topic)

      ER.Accounts.create_api_key_destination(api_key, destination)

      api_key = Repo.preload(api_key, :destinations)

      assert ApiKey.allowed_destination?(api_key, topic.name) == true
    end

    test "return false when a topic is not allowed", %{topic: topic} do
      api_key = insert(:api_key)

      api_key = Repo.preload(api_key, :destinations)

      assert ApiKey.allowed_destination?(api_key, topic.name) == false
    end
  end
end
