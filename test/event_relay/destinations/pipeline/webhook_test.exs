defmodule ER.Destinations.Pipeline.WebhookTest do
  use ER.DataCase
  import ER.Factory
  import Flamel.Wrap
  alias Broadway.Message
  alias ER.Events
  alias ER.Destinations
  alias ER.Destinations.Pipeline.Webhook
  alias ER.Repo

  describe "handle_retry/3" do
    setup do
      {:ok, topic} = Events.create_topic(%{name: "users"})

      {:ok, event} =
        params_for(:event, topic: topic)
        |> Events.create_event_for_topic()

      message = %Message{data: event, acknowledger: Broadway.NoopAcknowledger.init()}
      destination = insert(:destination, config: %{"retries" => %{"max_attempts" => 5}})
      {:ok, destination: destination, event: event, topic: topic, message: message}
    end

    test "returns updated delivery with status of failure when max_attempts are reached", %{
      message: message,
      destination: destination,
      event: event,
      topic: topic
    } do
      delivery =
        Destinations.create_delivery_for_topic(topic.name, %{
          event_id: event.id,
          destination_id: destination.id,
          status: :pending
        })
        |> unwrap_ok!()
        |> Repo.preload(:destination)

      attempts = [
        %{"response" => 1},
        %{"response" => 1},
        %{"response" => 1},
        %{"response" => 1},
        %{"response" => 1}
      ]

      {message, delivery} = Webhook.handle_retry(message, delivery, attempts)

      assert message.status == :ok
      assert delivery.status == :failure
    end

    test "returns failed message if there are more retries", %{
      message: message,
      destination: destination,
      event: event,
      topic: topic
    } do
      delivery =
        Destinations.create_delivery_for_topic(topic.name, %{
          event_id: event.id,
          destination_id: destination.id,
          status: :pending
        })
        |> unwrap_ok!()
        |> Repo.preload(:destination)

      attempts = [
        %{"response" => 1}
      ]

      {message, delivery} = Webhook.handle_retry(message, delivery, attempts)

      assert message.status == {:failed, "retry"}
      assert delivery.status == :pending

      attempts = [
        %{"response" => 1},
        %{"response" => 1}
      ]

      {message, delivery} = Webhook.handle_retry(message, delivery, attempts)

      assert message.status == {:failed, "retry"}
      assert delivery.status == :pending
    end
  end
end
