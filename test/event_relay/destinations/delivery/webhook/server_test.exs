defmodule ER.Destinations.Delivery.Webhook.ServerTest do
  use ER.DataCase
  import ER.Factory

  alias ER.{Destinations, Events}
  alias Destinations.Webhook.Delivery.Server

  setup do
    bypass = Bypass.open()
    {:ok, topic} = Events.create_topic(%{name: "users"})
    webhook_url = "http://localhost:#{bypass.port}"
    event = insert(:event, topic: topic, name: "user.created", data: %{"first_name" => "Bill"})
    delivery = insert(:delivery, event_id: event.id)

    destination =
      insert(:destination,
        name: "users_webhook",
        topic: topic,
        config: %{"endpoint_url" => webhook_url}
      )

    state = %{"event" => event, "destination" => destination, "delivery" => delivery}

    {:ok, bypass: bypass, webhook_url: webhook_url, state: state}
  end

  describe "handle_continue/2" do
    test "returns loaded state", %{
      bypass: _bypass,
      webhook_url: webhook_url,
      state: state = %{"event" => event, "destination" => destination, "delivery" => delivery}
    } do
      ending_state = build_state(webhook_url, event, destination, delivery)

      assert {:noreply, ending_state} == Server.handle_continue(:load_state, state)
    end
  end

  describe "handle_info/2" do
    test "returns state with updated attempt_count and delivery_attempts", %{
      bypass: bypass,
      webhook_url: webhook_url,
      state: %{"event" => event, "destination" => destination, "delivery" => delivery}
    } do
      response_body = Jason.encode!(event)

      Bypass.expect(bypass, &Plug.Conn.resp(&1, 200, response_body))

      starting_state = build_state(webhook_url, event, destination, delivery)

      {:stop, :shutdown, ending_state} = Server.handle_info(:attempt, starting_state)

      delivery_attempts = [delivery_attempt | _] = ending_state["delivery_attempts"]

      assert 1 == ending_state["attempt_count"]
      assert 1 == length(delivery_attempts)
      assert 200 == delivery_attempt["response"].status_code
    end
  end

  defp build_state(
         endpoint_url,
         event,
         destination,
         delivery,
         attempt_count \\ 0
       ) do
    %{
      "id" => delivery.id,
      "attempt_count" => attempt_count,
      "delivery" => delivery,
      "delivery_attempts" => [],
      "destination" => destination,
      "destination_endpoint_url" => endpoint_url,
      "destination_id" => destination.id,
      "destination_name" => destination.name,
      "destination_signing_secret" => destination.signing_secret,
      "destination_topic_identifier" => destination.topic_identifier,
      "destination_topic_name" => destination.topic_name,
      "event" => event,
      "max_attempts" => 10,
      "retry_delay" => calculate_retry_delay(attempt_count)
    }
  end

  defp calculate_retry_delay(0), do: 30000
  defp calculate_retry_delay(attempt_count) when attempt_count >= 1, do: 30000 * attempt_count
end
