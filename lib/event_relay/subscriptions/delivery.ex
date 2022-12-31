defmodule ER.Subscriptions.Delivery do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "deliveries" do
    field :attempts, {:array, :map}
    belongs_to :event, ER.Events.Event, foreign_key: :event_id, references: :id, type: :binary_id

    belongs_to :subscription, ER.Subscriptions.Subscription,
      foreign_key: :subscription_id,
      references: :id,
      type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [:attempts, :event_id, :subscription_id])
    |> validate_required([:attempts, :event_id, :subscription_id])
    |> assoc_constraint(:event)
    |> assoc_constraint(:subscription)
  end
end
