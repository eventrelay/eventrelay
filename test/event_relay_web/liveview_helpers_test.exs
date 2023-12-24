defmodule ERWeb.LiveViewHelpersTest do
  use ERWeb.ConnCase

  # import Phoenix.LiveViewTest

  import ER.Factory
  alias ERWeb.LiveViewHelpers, as: Helpers

  describe "api_key_has_topic?/2" do
    setup do
      topic = insert(:topic)

      api_key = insert(:api_key)
      {:ok, topic: topic, api_key: api_key}
    end

    test "return true if the api_key has a topic associated with it", %{
      api_key: api_key,
      topic: topic
    } do
      ER.Accounts.create_api_key_topic(api_key, topic)
      assert Helpers.api_key_has_topic?(api_key, topic) == true
    end

    test "return false if the api_key does not have a topic associated with it", %{
      api_key: api_key,
      topic: topic
    } do
      assert Helpers.api_key_has_topic?(api_key, topic) == false
    end
  end

  describe "api_key_has_destination?/2" do
    setup do
      destination = insert(:destination)

      api_key = insert(:api_key)
      {:ok, destination: destination, api_key: api_key}
    end

    test "return true if the api_key has a destination associated with it", %{
      api_key: api_key,
      destination: destination
    } do
      ER.Accounts.create_api_key_destination(api_key, destination)
      assert Helpers.api_key_has_destination?(api_key, destination) == true
    end

    test "return false if the api_key does not have a destination associated with it", %{
      api_key: api_key,
      destination: destination
    } do
      assert Helpers.api_key_has_destination?(api_key, destination) == false
    end
  end
end
