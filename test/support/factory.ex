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

  def destination_factory do
    %ER.Destinations.Destination{
      name: sequence(:name, &"Destination Name #{&1}"),
      ordered: false,
      paused: false,
      config: %{},
      topic: build(:topic),
      destination_type: "webhook",
      signing_secret: ER.Auth.generate_secret()
    }
  end

  def delivery_factory do
    %ER.Destinations.Delivery{
      attempts: [],
      destination: build(:destination),
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
      name: Faker.Person.name(),
      key: key,
      secret: secret,
      status: "active",
      type: "consumer",
      tls_hostname: Faker.Internet.domain_name()
    }
  end

  def api_key_destination_factory do
    %ER.Accounts.ApiKeyDestination{
      api_key: build(:api_key),
      destination: build(:destination)
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
      source: build(:source)
    }
  end

  def source_factory do
    key =
      :crypto.strong_rand_bytes(42)
      |> Base.url_encode64()
      |> binary_part(0, 42)

    secret =
      :crypto.strong_rand_bytes(42)
      |> Base.url_encode64()
      |> binary_part(0, 42)

    %ER.Sources.Source{
      config: %{},
      type: :webhook,
      source: "webhook",
      topic: build(:topic),
      key: key,
      secret: secret
    }
  end

  def metric_factory do
    %ER.Metrics.Metric{
      name: sequence(:name, &"Metric Name #{&1}"),
      type: :count,
      field_path: "data.cart.total"
    }
  end

  def pruner_factory do
    %ER.Pruners.Pruner{
      name: sequence(:name, &"Pruner Name #{&1}"),
      topic: build(:topic),
      query: "",
      config: %{},
      type: :count
    }
  end
end
