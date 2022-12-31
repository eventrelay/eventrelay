defmodule ER.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: ER.Repo

  def event_factory do
    %ER.Events.Event{
      context: %{},
      data: %{},
      name: "some name",
      occurred_at: ~U[2022-12-21 18:27:00Z],
      offset: Enum.random(0..9_999_999),
      source: "some source"
    }
  end

  def topic_factory do
    %ER.Events.Topic{
      name:
        Faker.Internet.slug() |> String.replace(~r/[^[:alnum:]\w]/, "_") |> String.slice(0..45)
    }
  end

  def subscription_factory do
    %ER.Subscriptions.Subscription{
      name: "some name",
      offset: 42,
      ordered: false,
      push: true,
      paused: false,
      config: %{},
      topic: build(:topic),
      topic_identifier: "some_topic_identifier"
    }
  end

  def delivery_factory do
    %ER.Subscriptions.Delivery{
      attempts: [],
      event: build(:event),
      subscription: build(:subscription)
    }
  end
end
