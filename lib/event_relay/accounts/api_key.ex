defmodule ER.Accounts.ApiKey do
  @moduledoc """
  ApiKey schema
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Accounts.ApiKeyDestination
  alias ER.Destinations.Destination
  alias ER.Accounts.ApiKeyTopic
  alias ER.Events.Topic
  alias __MODULE__
  import ER

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "api_keys" do
    field(:name, :string)
    field(:key, :string)
    field(:secret, :string)
    field(:status, Ecto.Enum, values: [:active, :revoked])
    field(:type, Ecto.Enum, values: [:admin, :producer, :consumer, :producer_consumer])
    field(:group_key, :string)
    field(:tls_key, :string)
    field(:tls_crt, :string)
    field(:tls_hostname, :string)

    # handles authorization for consumers
    has_many(:api_key_destinations, ApiKeyDestination, on_delete: :delete_all)
    many_to_many(:destinations, Destination, join_through: ApiKeyDestination)

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
    api_key =
      ApiKey.build(
        indifferent_get(attrs, :name),
        indifferent_get(attrs, :tls_hostname),
        indifferent_get(attrs, :type),
        indifferent_get(attrs, :status)
      )

    api_token
    |> cast(attrs, [:name, :key, :secret, :status, :type, :group_key, :tls_hostname])
    |> put_key(api_key)
    |> put_secret(api_key)
    |> put_tls_key(api_key)
    |> put_tls_crt(api_key)
    |> validate_required([:name, :key, :secret, :status, :type])
    |> unique_constraint(:key_secret_status_type_unique,
      name: :api_keys_key_secret_status_type_index
    )
  end

  def changeset(api_token, attrs) do
    api_token
    |> cast(attrs, [:name, :key, :secret, :status, :type, :group_key])
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

  def put_tls_key(cs, api_key) do
    put_change(cs, :tls_key, api_key.tls_key)
  end

  def put_tls_crt(cs, api_key) do
    put_change(cs, :tls_crt, api_key.tls_crt)
  end

  def encode_key_and_secret(%ApiKey{key: key, secret: secret} = _api_key) do
    Base.encode64(key <> ":" <> secret)
  end

  def allowed_topic?(api_key, topic_name) do
    allowed_topic_names = Enum.map(api_key.topics, & &1.name)

    if topic_name in allowed_topic_names do
      true
    else
      false
    end
  end

  def allowed_destination?(api_key, topic_name) do
    allowed_destination_topic_names = Enum.map(api_key.destinations, & &1.topic_name)

    if topic_name in allowed_destination_topic_names do
      true
    else
      false
    end
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

  def build(name, tls_hostname, type, status \\ :active) do
    {key, crt} =
      if ER.Env.use_grpc_tls?() do
        generate_tls(name, tls_hostname)
      else
        {nil, nil}
      end

    %ApiKey{
      name: name,
      key: ER.Auth.generate_key(),
      secret: ER.Auth.generate_secret(),
      status: status,
      type: type,
      tls_key: key,
      tls_crt: crt
    }
  end

  defp generate_tls(name, tls_hostname) do
    alt_names = to_string(tls_hostname) |> String.split(",") |> Enum.map(&String.trim/1)
    ER.CA.generate_key_and_crt(name, alt_names)
  end
end
