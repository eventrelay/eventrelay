defmodule ER.Accounts.ApiKey do
  @moduledoc """
  ApiKey schema
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Accounts.ApiKeySubscription
  alias ER.Subscriptions.Subscription
  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "api_keys" do
    field(:key, :string)
    field(:secret, :string)
    field(:status, Ecto.Enum, values: [:active, :revoked])
    field(:type, Ecto.Enum, values: [:admin, :producer, :consumer])
    has_many(:api_key_subscriptions, ApiKeySubscription)

    many_to_many(:subscriptions, Subscription,
      join_through: ApiKeySubscription,
      on_delete: :delete_all
    )

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(api_token, attrs) do
    api_token
    |> cast(attrs, [:key, :secret, :status, :type])
    |> validate_required([:key, :secret, :status, :type])
    |> unique_constraint(:key_secret_status_type_unique,
      name: :api_keys_key_secret_status_type_index
    )
  end

  def encode_key_and_secret(%ApiKey{key: key, secret: secret} = _api_key) do
    Base.encode64(key <> ":" <> secret)
  end

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
