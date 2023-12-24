defmodule ER.Accounts.ApiKeyDestination do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Accounts.ApiKey
  alias ER.Destinations.Destination

  @primary_key false
  schema "api_key_destinations" do
    belongs_to(:api_key, ApiKey, type: :binary_id, primary_key: true)
    belongs_to(:destination, Destination, type: :binary_id, primary_key: true)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(api_key_destination, attrs) do
    api_key_destination
    |> cast(attrs, [:api_key_id, :destination_id])
    |> validate_required([:api_key_id, :destination_id])
    |> unique_constraint([:api_key_id, :destination_id],
      message: "already has one of the destinations associated"
    )
  end
end
