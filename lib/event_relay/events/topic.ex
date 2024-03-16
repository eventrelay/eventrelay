defmodule ER.Events.Topic do
  use ER.Ecto.Schema
  import Ecto.Changeset
  alias ER.Events.Event
  alias __MODULE__
  alias ER.Events.EventConfig

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
          events: [Event.t()],
          event_configs: [EventConfig.t()]
        }

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :group_key
           ]}

  schema "topics" do
    field :name, :string
    field :group_key, :string
    has_many :events, Event, foreign_key: :topic_name, references: :name
    # embeds_many :event_configs, EventConfig, load_in_query: false
    embeds_many :event_configs, EventConfig, on_replace: :delete
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
    if ER.empty?(topic_identifier) do
      topic_name
    else
      "#{topic_name}:#{topic_identifier}"
    end
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:name, :group_key])
    |> validate_required([:name])
    # this is the max length of a topic name because of postgres table name and foreign key length limits
    |> validate_length(:name, max: 45)
    |> unique_constraint(:name)
    |> ER.Schema.normalize_name()
    |> cast_embed(:event_configs, with: &event_config_changeset/2)
  end

  def event_config_changeset(event_config, attrs) do
    event_config
    |> cast(attrs, [:name, :schema])
    |> validate_required([:name, :schema])
  end
end
