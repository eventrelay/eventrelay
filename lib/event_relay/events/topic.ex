defmodule ER.Events.Topic do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Events.Event
  alias __MODULE__

  @typedoc """
  The name for the topic.
  """
  @type topic_name :: String.t()

  @typedoc """
  An identifier for the topic.
  """
  @type topic_identifier :: String.t()

  @typedoc """
  The topic schema.
  """
  @type t :: %__MODULE__{
          name: topic_name(),
          events: [Event.t()]
        }

  @derive {Jason.Encoder,
           only: [
             :id,
             :name
           ]}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "topics" do
    field :name, :string
    has_many :events, Event, foreign_key: :topic_name, references: :name

    timestamps(type: :utc_datetime)
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
  def parse_topic(topic) when is_binary(topic) do
    topic_parts = String.split(topic, ":", trim: true)
    topic_name = List.first(topic_parts)
    {topic_identifier, _} = List.pop_at(topic_parts, 1)
    {topic_name, topic_identifier}
  end

  def parse_topic(%Topic{} = topic) do
    parse_topic(topic.name)
  end

  @spec build_topic(String.t(), String.t()) :: String.t()
  def build_topic(topic_name, topic_identifier \\ "") do
    unless ER.empty?(topic_identifier) do
      "#{topic_name}:#{topic_identifier}"
    else
      topic_name
    end
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:name])
    |> validate_required([:name])
    # this is the max length of a topic name because of postgres table name and foreign key length limits
    |> validate_length(:name, max: 45)
    |> unique_constraint(:name)
    |> ER.Schema.normalize_name()
  end
end
