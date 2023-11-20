defmodule ER.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: ER.Repo

  def event_factory do
    %ER.Events.Event{
      context: %{},
      data: %{},
      name: "some name",
      occurred_at: DateTime.to_iso8601(~U[2022-12-21 18:27:00Z]),
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
      name: Faker.Lorem.word(),
      offset: 42,
      ordered: false,
      push: true,
      paused: false,
      config: %{},
      topic: build(:topic),
      topic_identifier: "some_topic_identifier",
      subscription_type: "webhook"
    }
  end

  def delivery_factory do
    %ER.Subscriptions.Delivery{
      attempts: [],
      subscription: build(:subscription),
      status: :pending
    }
  end

  def api_key_factory do
    key =
      :crypto.strong_rand_bytes(42)
      |> Base.url_encode64()
      |> binary_part(0, 42)

    secret =
      :crypto.strong_rand_bytes(42)
      |> Base.url_encode64()
      |> binary_part(0, 42)

    %ER.Accounts.ApiKey{
      key: key,
      secret: secret,
      status: "active",
      type: "consumer"
    }
  end

  def api_key_subscription_factory do
    %ER.Accounts.ApiKeySubscription{
      api_key: build(:api_key),
      subscription: build(:subscription)
    }
  end

  def api_key_topic_factory do
    %ER.Accounts.ApiKeyTopic{
      api_key: build(:api_key),
      topic: build(:topic)
    }
  end

  def transformer_factory do
    %ER.Transformers.Transformer{
      script: "return { event = 2}",
      ingestor: build(:ingestor)
    }
  end

  def ingestor_factory do
    %ER.Ingestors.Ingestor{
      config: %{"subscription" => "test"},
      type: :google_pubsub,
      source: "GooglePubSub",
      topic: build(:topic)
    }
  end

  def metric_factory do
    %ER.Metrics.Metric{
      name: Faker.Lorem.word(),
      type: :count,
      field_path: "data.cart.total"
    }
  end
end
