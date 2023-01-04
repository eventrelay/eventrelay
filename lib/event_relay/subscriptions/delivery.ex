defmodule ER.Subscriptions.Delivery do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :attempts
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "deliveries" do
    field :attempts, {:array, :map}, default: []
    field :success, :boolean, default: false
    field :event_id, :binary_id

    belongs_to :subscription, ER.Subscriptions.Subscription,
      foreign_key: :subscription_id,
      references: :id,
      type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [:attempts, :event_id, :subscription_id])
    |> validate_required([:event_id, :subscription_id])
    |> unique_constraint([:event_id, :subscription_id])
  end
end
