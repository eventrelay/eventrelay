defmodule ER.Accounts.ApiKeyTopic do
  use ER.Ecto.Schema
  import Ecto.Changeset
  alias ER.Accounts.ApiKey
  alias ER.Events.Topic

  @primary_key false
  schema "api_key_topics" do
    belongs_to(:api_key, ApiKey, type: :binary_id, primary_key: true)

    belongs_to :topic, Topic,
      foreign_key: :topic_name,
      references: :name,
      type: :string,
      primary_key: true

    timestamps()
  end

  @doc false
  def changeset(api_key_topic, attrs) do
    api_key_topic
    |> cast(attrs, [:api_key_id, :topic_name])
    |> validate_required([:api_key_id, :topic_name])
    |> unique_constraint([:api_key_id, :topic_name],
      message: "already has one of the topics associated"
    )
  end
end
