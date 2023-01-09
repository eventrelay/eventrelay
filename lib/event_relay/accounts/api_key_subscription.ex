defmodule ER.Accounts.ApiKeySubscription do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Accounts.ApiKey
  alias ER.Subscriptions.Subscription

  @primary_key false
  schema "api_key_subscriptions" do
    belongs_to(:api_key, ApiKey, primary_key: true)
    belongs_to(:subscription, Subscription, primary_key: true)

    timestamps()
  end

  @doc false
  def changeset(api_key_subscription, attrs) do
    api_key_subscription
    |> cast(attrs, [:api_key_id, :subscription_id])
    |> validate_required([:api_key_id, :subscription_id])
  end
end
