defmodule ER.Destinations.Pipeline.WebhookTest do
  use ER.DataCase
  import ER.Factory
  import Flamel.Wrap
  alias Broadway.Message
  alias ER.Events
  alias ER.Destinations
  alias ER.Destinations.Pipeline.Webhook
  alias ER.Repo
  require Flamel.Moment.CurrentTime

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

      destination = delivery.destination
      assert destination.paused == false

      attempts = [
        %{"response" => 1},
        %{"response" => 1},
        %{"response" => 1},
        %{"response" => 1},
        %{"response" => 1}
      ]

      response = {:ok, %{}}

      {message, delivery} = Webhook.handle_retry(message, delivery, attempts, response)

      assert message.status == :ok
      assert delivery.status == :failure

      destination = Repo.reload(destination)
      assert destination.paused == false
    end

    test "returns updated delivery with status of failure when response is a 410", %{
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

      destination = delivery.destination
      assert destination.paused == false

      attempts = [
        %{"response" => 1}
      ]

      response = {:error, %{status: 410}}

      {message, delivery} = Webhook.handle_retry(message, delivery, attempts, response)

      assert message.status == :ok
      assert delivery.status == :failure

      # we also want to pause the destination if we get a 410
      destination = Repo.reload(destination)
      assert destination.paused == true
    end

    test "returns updated delivery with status of pending and proper available_at when response contains a retry-after header and the value is a time in seconds",
         %{
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

      retry_after = 120
      response = {:error, %{status: 503, headers: %{"RETRY-AFTER" => retry_after}}}

      now = Flamel.Moment.to_datetime("2022-01-01T12:34:56Z")

      Flamel.Moment.CurrentTime.time_travel now do
        {message, delivery} = Webhook.handle_retry(message, delivery, attempts, response)
        event = Events.get_event_for_topic!(event.id, topic_name: event.topic_name)
        expected_available_at = DateTime.add(now, retry_after, :second)
        assert event.available_at == expected_available_at

        assert message.status == {:failed, "retry"}
        assert delivery.status == :pending
      end
    end

    test "returns updated delivery with status of pending and proper available_at when response contains a retry-after header and the value is a datetime",
         %{
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

      expected_available_at = Flamel.Moment.to_datetime("2022-01-01T12:38:56Z")

      retry_after = Calendar.DateTime.Format.rfc2822(expected_available_at)

      response = {:error, %{status: 503, headers: %{"RETRY-AFTER" => retry_after}}}

      now = Flamel.Moment.to_datetime("2022-01-01T12:34:56Z")

      Flamel.Moment.CurrentTime.time_travel now do
        {message, delivery} = Webhook.handle_retry(message, delivery, attempts, response)
        event = Events.get_event_for_topic!(event.id, topic_name: event.topic_name)

        assert event.available_at == expected_available_at

        assert message.status == {:failed, "retry"}
        assert delivery.status == :pending
      end
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

      response = {:ok, %{}}

      {message, delivery} = Webhook.handle_retry(message, delivery, attempts, response)

      assert message.status == {:failed, "retry"}
      assert delivery.status == :pending

      attempts = [
        %{"response" => 1},
        %{"response" => 1}
      ]

      {message, delivery} = Webhook.handle_retry(message, delivery, attempts, response)

      assert message.status == {:failed, "retry"}
      assert delivery.status == :pending
    end
  end
end
