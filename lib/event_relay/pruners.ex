defmodule ER.Pruners do
  @moduledoc """
  The Pruners context.
  """

  import Ecto.Query, warn: false
  alias ER.Repo
  alias Phoenix.PubSub

  alias ER.Pruners.Pruner

  @doc """
  Returns the list of pruners.

  ## Examples

      iex> list_pruners()
      [%Pruner{}, ...]

  """
  def list_pruners do
    Repo.all(Pruner)
  end

  @doc """
  Gets a single pruner.

  Raises `Ecto.NoResultsError` if the Pruner does not exist.

  ## Examples

      iex> get_pruner!(123)
      %Pruner{}

      iex> get_pruner!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pruner!(id), do: Repo.get!(Pruner, id)

  @doc """
  Creates a pruner.

  ## Examples

      iex> create_pruner(%{field: value})
      {:ok, %Pruner{}}

      iex> create_pruner(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pruner(attrs \\ %{}) do
    %Pruner{}
    |> Pruner.changeset(attrs)
    |> Repo.insert()
    |> publish_pruner_created()
  end

  @doc """
  Updates a pruner.

  ## Examples

      iex> update_pruner(pruner, %{field: new_value})
      {:ok, %Pruner{}}

      iex> update_pruner(pruner, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pruner(%Pruner{} = pruner, attrs) do
    pruner
    |> Pruner.changeset(attrs)
    |> Repo.update()
    |> publish_pruner_updated()
  end

  @doc """
  Deletes a pruner.

  ## Examples

      iex> delete_pruner(pruner)
      {:ok, %Pruner{}}

      iex> delete_pruner(pruner)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pruner(%Pruner{} = pruner) do
    Repo.delete(pruner)
    |> publish_pruner_deleted()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pruner changes.

  ## Examples

      iex> change_pruner(pruner)
      %Ecto.Changeset{data: %Pruner{}}

  """
  def change_pruner(%Pruner{} = pruner, attrs \\ %{}) do
    Pruner.changeset(pruner, attrs)
  end

  def publish_pruner_created({:ok, pruner}) do
    PubSub.broadcast(ER.PubSub, "pruner:created", {:pruner_created, pruner.id})
    {:ok, pruner}
  end

  def publish_pruner_created(result) do
    result
  end

  def publish_pruner_updated({:ok, pruner}) do
    PubSub.broadcast(ER.PubSub, "pruner:updated", {:pruner_updated, pruner.id})
    {:ok, pruner}
  end

  def publish_pruner_updated(result) do
    result
  end

  def publish_pruner_deleted({:ok, pruner}) do
    PubSub.broadcast(ER.PubSub, "pruner:deleted", {:pruner_deleted, pruner.id})
    {:ok, pruner}
  end

  def publish_pruner_deleted(result) do
    result
  end
end
