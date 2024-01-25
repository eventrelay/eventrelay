defmodule ER.Transformers do
  require Logger
  alias ER.Repo

  def factory(%{type: :lua} = transformer),
    do: %ER.Transformers.LuaTransformer{transformer: transformer}

  def factory(%{type: :liquid} = transformer),
    do: %ER.Transformers.LiquidTransformer{transformer: transformer}

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
