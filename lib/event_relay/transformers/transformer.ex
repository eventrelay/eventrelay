defmodule ER.Transformers.Transformer do
  use ER.Ecto.Schema
  require Logger
  import Ecto.Changeset
  alias ER.Destinations.Destination
  alias ER.Sources.Source
  alias ER.Transformers.Transformation
  alias ER.Transformers.TransformationContext
  alias __MODULE__
  alias ER.Repo

  schema "transformers" do
    field :script, :string
    belongs_to(:source, Source)
    belongs_to(:destination, Destination)
    field(:type, Ecto.Enum, values: [:lua, :liquid])
    field(:return_type, Ecto.Enum, values: [:map])
    field :query, :string
    timestamps()
  end

  @doc false
  def changeset(transformer, attrs) do
    transformer
    |> cast(attrs, [:script, :source_id, :return_type, :query])
    |> Flamel.Ecto.Validators.validate_at_least_one_required(
      [:destination_id, :source_id],
      "must select either a source or destination"
    )
    |> validate_required([:script, :return_type])
  end

  def matches?(%Transformer{query: nil}, _data), do: false

  def matches?(%Transformer{query: query}, data) do
    if Flamel.present?(query), do: Predicated.test(query, data), else: false
  end

  def find_transformer(source_or_destination, data) do
    source_or_destination
    |> Repo.preload(:transformers)
    |> Map.get(:transformers)
    |> Enum.find(fn transformer ->
      matches?(transformer, data)
    end)
  end

  def transform(data, source_or_destination) do
    find_transformer(source_or_destination, data)
    |> transform(data, source_or_destination)
  end

  def transform(nil, attrs, _source_or_destination) do
    Logger.debug("#{__MODULE__}.forward no transformer found.")
    attrs
  end

  def transform(transformer, attrs, source_or_destination) do
    transformer
    |> ER.Transformers.factory()
    |> Transformation.perform(
      event: attrs,
      context: TransformationContext.build(source_or_destination)
    )
    |> case do
      nil ->
        attrs

      attrs ->
        attrs = Flamel.Map.atomize_keys(attrs)

        attrs
        |> Map.put(:data, Flamel.Map.stringify_keys(attrs[:data] || %{}))
        |> Map.put(:context, Flamel.Map.stringify_keys(attrs[:context] || %{}))
    end
  end
end
