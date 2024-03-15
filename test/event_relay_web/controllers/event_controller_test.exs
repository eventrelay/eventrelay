defmodule ERWeb.EventControllerTest do
  use ERWeb.ConnCase

  alias ER.Events
  alias ER.Accounts.ApiKey
  import ER.Factory

  def setup_auth(%{conn: conn, topic: topic}) do
    api_key = insert(:api_key, type: :producer)
    insert(:api_key_topic, topic: topic, api_key: api_key)

    token = ApiKey.encode_key_and_secret(api_key)

    {:ok, conn: put_req_header(conn, "authorization", "Bearer #{token}"), api_key: api_key}
  end

  setup %{conn: conn} do
    {:ok, topic} = Events.create_topic(%{name: "log"})

    {:ok, conn: put_req_header(conn, "accept", "application/json"), topic: topic}
  end

  describe "publish events" do
    setup [:setup_auth]

    test "renders events when data is valid", %{conn: conn, topic: topic} do
      conn =
        post(conn, ~p"/api/events",
          topic: topic.name,
          durable: true,
          events: [%{name: "user.updated", source: "myapp", data: %{username: "tester"}}]
        )

      response(conn, 201)
    end

    test "renders error when no topic is passed", %{conn: conn} do
      conn = post(conn, ~p"/api/events", topic: "", durable: false, events: [])
      errors = json_response(conn, 409)["errors"]
      assert ["A topic must be provided"] == errors
    end

    # TODO write test for authorization
  end

  describe "publish events unauthenticated" do
    test "renders events when data is valid", %{conn: conn, topic: topic} do
      conn =
        post(conn, ~p"/api/events",
          topic: topic.name,
          durable: true,
          events: [%{name: "user.updated", source: "myapp", data: %{username: "tester"}}]
        )

      assert %{"errors" => ["Unauthorized"]} == json_response(conn, 401)
    end
  end
end
