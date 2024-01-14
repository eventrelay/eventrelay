defmodule ER.Transformers do
  require Logger
  alias ER.Repo

  def run(%{script: script, return_type: return_type}, globals) do
    script
    |> ER.Lua.eval(globals)
    |> debug(:pre_return)
    |> return(return_type)
    |> debug(:post_return)
  end

  def return(data, :map) do
    to_map(data)
  end

  def return(data, _) do
    data
  end

  def debug(thing, label) do
    if ER.Env.debug_transformers() do
      # credo:disable-for-next-line Credo.Check.Warning.IoInspect
      IO.inspect(thing, label: label)
    else
      thing
    end
  end

  def to_map(list, acc \\ %{})

  def to_map([head | rest], acc) do
    acc =
      case head do
        # we have a nested map
        {key, [{_, _} | _] = t} ->
          Map.put(acc, key, to_map(t))

        {key, val} ->
          Map.put(acc, key, val)

        # ignoring this val
        unexpected ->
          Logger.debug("ER.Transformers.GooglePubsub.to_map unexpected=#{inspect(unexpected)}")
          acc
      end

    to_map(rest, acc)
  end

  def to_map([], acc) do
    acc
  end

  alias ER.Transformers.Transformer

  @doc """
  Returns the list of transformers.

  ## Examples

      iex> list_transformers()
      [%Transformer{}, ...]

  """
  def list_transformers do
    Repo.all(Transformer)
  end

  @doc """
  Gets a single transformer.

  Raises `Ecto.NoResultsError` if the Transformer does not exist.

  ## Examples

      iex> get_transformer!(123)
      %Transformer{}

      iex> get_transformer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transformer!(id), do: Repo.get!(Transformer, id)

  @doc """
  Creates a transformer.

  ## Examples

      iex> create_transformer(%{field: value})
      {:ok, %Transformer{}}

      iex> create_transformer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transformer(attrs \\ %{}) do
    %Transformer{}
    |> Transformer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a transformer.

  ## Examples

      iex> update_transformer(transformer, %{field: new_value})
      {:ok, %Transformer{}}

      iex> update_transformer(transformer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_transformer(%Transformer{} = transformer, attrs) do
    transformer
    |> Transformer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a transformer.

  ## Examples

      iex> delete_transformer(transformer)
      {:ok, %Transformer{}}

      iex> delete_transformer(transformer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transformer(%Transformer{} = transformer) do
    Repo.delete(transformer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transformer changes.

  ## Examples

      iex> change_transformer(transformer)
      %Ecto.Changeset{data: %Transformer{}}

  """
  def change_transformer(%Transformer{} = transformer, attrs \\ %{}) do
    Transformer.changeset(transformer, attrs)
  end
end
