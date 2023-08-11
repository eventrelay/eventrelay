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

  describe "api_key_has_subscription?/2" do
    setup do
      subscription = insert(:subscription)

      api_key = insert(:api_key)
      {:ok, subscription: subscription, api_key: api_key}
    end

    test "return true if the api_key has a subscription associated with it", %{
      api_key: api_key,
      subscription: subscription
    } do
      ER.Accounts.create_api_key_subscription(api_key, subscription)
      assert Helpers.api_key_has_subscription?(api_key, subscription) == true
    end

    test "return false if the api_key does not have a subscription associated with it", %{
      api_key: api_key,
      subscription: subscription
    } do
      assert Helpers.api_key_has_subscription?(api_key, subscription) == false
    end
  end
end
