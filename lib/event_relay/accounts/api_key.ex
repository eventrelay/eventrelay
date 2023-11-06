defmodule ER.Accounts.ApiKey do
  @moduledoc """
  ApiKey schema
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Accounts.ApiKeySubscription
  alias ER.Subscriptions.Subscription
  alias ER.Accounts.ApiKeyTopic
  alias ER.Events.Topic
  alias __MODULE__
  import ER
  alias ER.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "api_keys" do
    field(:key, :string)
    field(:secret, :string)
    field(:status, Ecto.Enum, values: [:active, :revoked])
    field(:type, Ecto.Enum, values: [:admin, :producer, :consumer])

    # handles authorization for consumers
    has_many(:api_key_subscriptions, ApiKeySubscription, on_delete: :delete_all)
    many_to_many(:subscriptions, Subscription, join_through: ApiKeySubscription)

    # handles authorization for producers
    has_many(:api_key_topics, ApiKeyTopic, on_delete: :delete_all)

    many_to_many(:topics, Topic,
      join_through: ApiKeyTopic,
      join_keys: [api_key_id: :id, topic_name: :name]
    )

    timestamps(type: :utc_datetime)
  end

  @doc false
  def create_changeset(api_token, attrs) do
    api_key = ApiKey.build(indifferent_get(attrs, :type), indifferent_get(attrs, :status))

    api_token
    |> cast(attrs, [:key, :secret, :status, :type])
    |> put_key(api_key)
    |> put_secret(api_key)
    |> validate_required([:key, :secret, :status, :type])
    |> unique_constraint(:key_secret_status_type_unique,
      name: :api_keys_key_secret_status_type_index
    )
  end

  def changeset(api_token, attrs) do
    api_token
    |> cast(attrs, [:key, :secret, :status, :type])
    |> validate_required([:key, :secret, :status, :type])
    |> unique_constraint(:key_secret_status_type_unique,
      name: :api_keys_key_secret_status_type_index
    )
  end

  def put_key(
        cs,
        api_key
      ) do
    put_change(cs, :key, api_key.key)
  end

  def put_secret(cs, api_key) do
    put_change(cs, :secret, api_key.secret)
  end

  def encode_key_and_secret(%ApiKey{key: key, secret: secret} = _api_key) do
    Base.encode64(key <> ":" <> secret)
  end

  def allowed_topic?(api_key, topic_name) do
    api_key = Repo.preload(api_key, :topics)
    allowed_topic_names = Enum.map(api_key.topics, & &1.name)
    topic_name in allowed_topic_names
  end

  def allowed_subscription?(api_key, topic_name) do
    api_key = Repo.preload(api_key, subscriptions: :topic)
    allowed_topic_names = api_key.subscriptions |> Enum.map(& &1.topic) |> Enum.map(& &1.name)
    topic_name in allowed_topic_names
  end

  def decode_key_and_secret(nil), do: {:error, :invalid_token}

  def decode_key_and_secret(token) do
    token
    |> Base.decode64()
    |> case do
      {:ok, decoded} ->
        decoded
        |> String.split(":")
        |> case do
          [key, secret] ->
            {:ok, key, secret}

          _ ->
            {:error, :invalid_token}
        end

      _ ->
        {:error, :invalid_token}
    end
  end

  @key_size 42
  @secret_size 64

  def build(type, status \\ :active) do
    key =
      :crypto.strong_rand_bytes(@key_size)
      |> Base.url_encode64()
      |> binary_part(0, @key_size)

    secret =
      :crypto.strong_rand_bytes(@secret_size)
      |> Base.url_encode64()
      |> binary_part(0, @secret_size)

    %ApiKey{
      key: key,
      secret: secret,
      status: status,
      type: type
    }
  end
end
