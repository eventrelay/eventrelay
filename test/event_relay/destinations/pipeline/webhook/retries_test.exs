defmodule ER.Destinations.Pipeline.Webhook.RetriesTest do
  use ER.DataCase
  import ER.Factory
  alias ER.Destinations.Pipeline.Webhook.Retries

  describe "next/2" do
    test "returns available_at time based on the destination config and delivery attempts" do
      {:ok, topic} = ER.Events.create_topic(%{name: "users"})

      destination =
        insert(:destination,
          destination_type: :webhook,
          config: %{
            "retries" => %{"max_attempts" => 10, "max_interval" => 999_000_000, "multiplier" => 2}
          },
          topic: topic
        )

      attrs =
        params_for(:event,
          topic: topic
        )

      {:ok, event} = ER.Events.create_event_for_topic(attrs)

      {:ok, delivery} =
        ER.Destinations.create_delivery_for_topic(topic.name, %{
          event_id: event.id,
          destination_id: destination.id,
          status: :pending,
          attempts: [%{"response" => "1"}]
        })

      now = DateTime.utc_now()

      assert Enum.count(delivery.attempts) == 1

      attempts = delivery.attempts

      {_strategy, available_at} = Retries.next(destination, delivery, attempts, now)

      # 2nd attempt
      assert available_at == DateTime.add(now, 60_000, :millisecond)

      attempts = [%{"response" => 2} | attempts]

      {_strategy, available_at} = Retries.next(destination, delivery, attempts, now)
      assert available_at == DateTime.add(now, 60_000 * 2, :millisecond)

      attempts = [%{"response" => 3} | attempts]

      {_strategy, available_at} = Retries.next(destination, delivery, attempts, now)
      assert available_at == DateTime.add(now, 60_000 * 4, :millisecond)

      attempts = [%{"response" => 4} | attempts]

      {_strategy, available_at} = Retries.next(destination, delivery, attempts, now)
      assert available_at == DateTime.add(now, 60_000 * 8, :millisecond)

      attempts = [%{"response" => 5} | attempts]
      {_strategy, available_at} = Retries.next(destination, delivery, attempts, now)
      assert available_at == DateTime.add(now, 60_000 * 16, :millisecond)

      attempts = [%{"response" => 6} | attempts]
      {_strategy, available_at} = Retries.next(destination, delivery, attempts, now)
      assert available_at == DateTime.add(now, 60_000 * 32, :millisecond)

      attempts = [%{"response" => 7} | attempts]
      {_strategy, available_at} = Retries.next(destination, delivery, attempts, now)
      assert available_at == DateTime.add(now, 60_000 * 64, :millisecond)

      attempts = [%{"response" => 8} | attempts]
      {_strategy, available_at} = Retries.next(destination, delivery, attempts, now)
      assert available_at == DateTime.add(now, 60_000 * 128, :millisecond)

      attempts = [%{"response" => 9} | attempts]
      {_strategy, available_at} = Retries.next(destination, delivery, attempts, now)
      assert available_at == DateTime.add(now, 60_000 * 256, :millisecond)

      attempts = [%{"response" => 10} | attempts]
      {strategy, available_at} = Retries.next(destination, delivery, attempts, now)
      assert available_at == nil
      assert Flamel.Context.halted?(strategy) == true
    end
  end
end
