defmodule ER.Destinations.WebhookTest do
  use ER.DataCase
  import ER.Factory
  alias ER.{Destinations, Events}
  alias Destinations.Webhook

  describe "webhook/6" do
    setup do
      bypass = Bypass.open()
      {:ok, topic} = Events.create_topic(%{name: "users"})

      webhook_url = "http://localhost:#{bypass.port}"

      destination =
        insert(:destination,
          name: "users_webhook",
          topic: topic,
          config: %{"endpoint_url" => webhook_url}
        )

      event = insert(:event, name: "user.created", data: %{"first_name" => "Bill"})

      {:ok, bypass: bypass, webhook_url: webhook_url, destination: destination, event: event}
    end

    test "returns HTTP 200 when successful", %{
      bypass: bypass,
      webhook_url: webhook_url,
      destination: destination,
      event: event
    } do
      response_body = Jason.encode!(event)

      Bypass.expect(bypass, fn conn ->
        assert "POST" == conn.method
        assert "/" == conn.request_path
        Plug.Conn.resp(conn, 200, response_body)
      end)

      {:ok, %HTTPoison.Response{status_code: status_code, body: body, request_url: request_url}} =
        webhook_request(webhook_url, event, destination)

      assert 200 == status_code
      assert response_body == body
      assert webhook_url == request_url
    end

    test "returns econnrefused error when unexpected outage", %{
      bypass: bypass,
      webhook_url: webhook_url,
      destination: destination,
      event: event
    } do
      Bypass.down(bypass)

      assert {:error, %HTTPoison.Error{reason: :econnrefused, id: nil}} ==
               webhook_request(webhook_url, event, destination)
    end

    test "returns HTTP 500 error", %{
      bypass: bypass,
      webhook_url: webhook_url,
      destination: destination,
      event: event
    } do
      Bypass.expect(bypass, fn conn ->
        assert "POST" == conn.method
        assert "/" == conn.request_path
        Plug.Conn.resp(conn, 500, "")
      end)

      {:ok, %HTTPoison.Response{status_code: status_code}} =
        webhook_request(webhook_url, event, destination)

      assert 500 == status_code
    end

    test "returns HTTP 2xx error", %{
      bypass: bypass,
      webhook_url: webhook_url,
      destination: destination,
      event: event
    } do
      Bypass.expect(bypass, fn conn ->
        assert "POST" == conn.method
        assert "/" == conn.request_path
        Plug.Conn.resp(conn, 200, "")
      end)

      {:ok, %HTTPoison.Response{status_code: status_code}} =
        webhook_request(webhook_url, event, destination)

      assert 200 == status_code
    end
  end

  defp webhook_request(webhook_url, event, destination) do
    Webhook.request(
      webhook_url,
      event,
      destination.id,
      destination.topic_name,
      destination.topic_identifier,
      destination.signing_secret
    )
  end
end
