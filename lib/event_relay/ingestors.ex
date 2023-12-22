defmodule ER.Ingestors do
  @moduledoc """
  The Ingestors context.
  """

  import Ecto.Query, warn: false
  alias ER.Repo

  alias ER.Ingestors.Ingestor

  @doc """
  Returns the list of ingestors.

  ## Examples

      iex> list_ingestors()
      [%Ingestor{}, ...]

  """
  def list_ingestors do
    Repo.all(Ingestor)
  end

  @doc """
  Gets a single ingestor.

  Raises `Ecto.NoResultsError` if the Ingestor does not exist.

  ## Examples

      iex> get_ingestor!(123)
      %Ingestor{}

      iex> get_ingestor!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ingestor!(id), do: Repo.get!(Ingestor, id)

  @doc """
  Creates a ingestor.

  ## Examples

      iex> create_ingestor(%{field: value})
      {:ok, %Ingestor{}}

      iex> create_ingestor(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ingestor(attrs \\ %{}) do
    %Ingestor{}
    |> Ingestor.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ingestor.

  ## Examples

      iex> update_ingestor(ingestor, %{field: new_value})
      {:ok, %Ingestor{}}

      iex> update_ingestor(ingestor, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ingestor(%Ingestor{} = ingestor, attrs) do
    ingestor
    |> Ingestor.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ingestor.

  ## Examples

      iex> delete_ingestor(ingestor)
      {:ok, %Ingestor{}}

      iex> delete_ingestor(ingestor)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ingestor(%Ingestor{} = ingestor) do
    Repo.delete(ingestor)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ingestor changes.

  ## Examples

      iex> change_ingestor(ingestor)
      %Ecto.Changeset{data: %Ingestor{}}

  """
  def change_ingestor(%Ingestor{} = ingestor, attrs \\ %{}) do
    Ingestor.changeset(ingestor, attrs)
  end
end
