defmodule ER.Accounts.ApiKeySubscription do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Accounts.ApiKey
  alias ER.Subscriptions.Subscription

  @primary_key false
  schema "api_key_subscriptions" do
    belongs_to(:api_key, ApiKey, type: :binary_id, primary_key: true)
    belongs_to(:subscription, Subscription, type: :binary_id, primary_key: true)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(api_key_subscription, attrs) do
    api_key_subscription
    |> cast(attrs, [:api_key_id, :subscription_id])
    |> validate_required([:api_key_id, :subscription_id])
    |> unique_constraint([:api_key_id, :subscription_id],
      message: "already has one of the subscriptions associated"
    )
  end
end
