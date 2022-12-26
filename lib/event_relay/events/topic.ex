defmodule ER.Events.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  alias ER.Events.Event

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "topics" do
    field :name, :string
    has_many :events, Event, foreign_key: :topic_name, references: :name

    timestamps()
  end

  @doc """
    Takes a topic string and returns the topic name and identifier.
    
    ## Examples:

      iex> ER.Events.Topic.parse_topic("users")
      {"users", nil}

      iex> ER.Events.Topic.parse_topic("users:123")
      {"users", "123"}

  """
  @spec parse_topic(String.t()) :: {String.t(), String.t()}
  def parse_topic(topic) do
    topic_parts = String.split(topic, ":", trim: true)
    topic_name = List.first(topic_parts)
    {topic_identifier, _} = List.pop_at(topic_parts, 1)
    {topic_name, topic_identifier}
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, max: 50)
    |> unique_constraint(:name)
  end
end
