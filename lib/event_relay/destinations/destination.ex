defmodule ER.Destinations.Destination do
  use Ecto.Schema
  import Ecto.Changeset
  alias ER.Events.Topic
  import ER.Config

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :topic_name,
             :topic_identifier,
             :offset,
             :ordered,
             :destination_type,
             :paused,
             :config,
             :group_key
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "destinations" do
    field :name, :string
    field :offset, :integer
    field :ordered, :boolean, default: false
    field(:destination_type, Ecto.Enum, values: [:api, :webhook, :websocket, :s3, :topic])
    field :paused, :boolean, default: false
    field :config, :map, default: %{}
    field :config_json, :string, virtual: true
    field :topic_identifier, :string
    field :group_key, :string
    field :signing_secret, :string
    field :query, :string

    belongs_to :topic, Topic, foreign_key: :topic_name, references: :name, type: :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(destination, attrs) do
    destination
    |> cast(attrs, [
      :name,
      :offset,
      :topic_name,
      :ordered,
      :paused,
      :config,
      :config_json,
      :topic_identifier,
      :destination_type,
      :group_key,
      :signing_secret,
      :query
    ])
    |> validate_required([:name, :topic_name, :destination_type])
    |> validate_length(:name, min: 3, max: 255)
    |> unique_constraint(:name)
    |> decode_config()
    |> put_signing_secret()
    |> ER.Schema.normalize_name()
    |> assoc_constraint(:topic)
    |> validate_inclusion(:destination_type, [:s3, :webhook, :websocket, :api, :topic])
  end

  def put_signing_secret(changeset) do
    # we only want to add the signing_secret if there is not one
    if changeset.data.signing_secret == nil do
      put_change(changeset, :signing_secret, ER.Auth.generate_secret())
    else
      changeset
    end
  end

  def api?(%{destination_type: :api}), do: true
  def api?(_), do: false

  def websocket?(%{destination_type: :websocket}), do: true
  def websocket?(_), do: false

  def webhook?(%{destination_type: :webhook}), do: true
  def webhook?(_), do: false

  def s3?(%{destination_type: :s3}), do: true
  def s3?(_), do: false

  def topic?(%{destination_type: :topic}), do: true
  def topic?(_), do: false

  def matches?(%{query: nil}, _event) do
    true
  end

  def matches?(%{query: query}, event) do
    event =
      Map.from_struct(event) |> Map.drop([:topic, :__meta__]) |> ER.atomize_map()

    Predicated.test(query, event)
  end

  # @type t :: %__MODULE__{
  #         attempt: integer(),
  #         max_attempts: integer(),
  #         multiplier: integer(),
  #         interval: Flamel.Retryable.interval(),
  #         max_interval: Flamel.Retryable.interval(),
  #         base: integer(),
  #         with_jitter?: boolean(),
  #         assigns: map(),
  #         halt?: boolean(),
  #         reason: binary() | nil
  #       }
  # defstruct attempt: 0,
  #           max_attempts: 5,
  #           multiplier: 2,
  #           interval: 0,
  #           base: 1_000,
  #           max_interval: 8_000,
  #           with_jitter?: false,
  #           assigns: %{},
  #           halt?: false,
  #           reason: nil

  defimpl Flamel.Retryable.Strategy do
    import Flamel.Context
    alias Flamel.Map.Safely

    @doc """
    Calculates a retry interval that is a exponential value
    """
    def calc(strategy) do
      max_attempts =
        Safely.get(strategy.config, &Flamel.to_integer(&1["max_attempts"]), 10)

      if Enum.count(strategy.attempts) == max_attempts do
        halt!(strategy, "max_attempts=#{inspect(max_attempts)} reached")
      else
        update_interval(strategy)
      end
    end

    defp calculate_randomness(%{
           config: %{"include_jitter" => "true"} = config
         }) do
      max_interval = Safely.get(config, &Flamel.to_integer(&1["max_interval"]), 10)
      max = trunc(max_interval * 0.25)
      Enum.random(0..max)
    end

    defp calculate_randomness(_) do
      0
    end

    defp update_interval(strategy) do
      max_interval = Safely.get(strategy.config, &Flamel.to_integer(&1["max_interval"]), 10)
      randomness = calculate_randomness(strategy)

      interval =
        case Enum.random([:plus, :minus]) do
          :plus ->
            calculate_interval(strategy) + randomness

          :minus ->
            calculate_interval(strategy) - randomness
        end
        |> then(fn
          interval when interval < 0 ->
            0

          interval when interval > max_interval ->
            max_interval

          interval ->
            interval
        end)

      interval =
        Enum.min([
          interval,
          max_interval
        ])

      struct!(strategy, interval: interval)
    end

    defp calculate_interval(strategy) do
      attempts = Enum.count(strategy.attempts)
      base = Safely.get(strategy.config, &Flamel.to_integer(&1["base"]), 1_000)
      multiplier = Safely.get(strategy.config, &Flamel.to_integer(&1["multiplier"]), 1_000)

      cond do
        attempts == 1 ->
          base

        attempts == 2 ->
          base * attempts

        true ->
          base * multiplier ** (attempts - 1)
      end
    end
  end

  defimpl Flamel.Contextable do
    use Flamel.Contextable.Base
  end
end
