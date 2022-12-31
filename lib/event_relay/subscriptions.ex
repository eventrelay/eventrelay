defmodule ER.Subscriptions do
  @moduledoc """
  The Subscriptions context.
  """
  alias Phoenix.PubSub, as: PubSub

  import Ecto.Query, warn: false
  alias ER.Repo

  alias ER.Subscriptions.Subscription

  @doc """
  Returns the list of subscriptions.

  ## Examples

      iex> list_subscriptions()
      [%Subscription{}, ...]

  """
  def list_subscriptions do
    Repo.all(Subscription)
  end

  @doc """
  Gets a single subscription.

  Raises `Ecto.NoResultsError` if the Subscription does not exist.

  ## Examples

      iex> get_subscription!(123)
      %Subscription{}

      iex> get_subscription!(456)
      ** (Ecto.NoResultsError)

  """
  def get_subscription!(id), do: Repo.get!(Subscription, id)

  @doc """
  Creates a subscription.

  ## Examples

      iex> create_subscription(%{field: value})
      {:ok, %Subscription{}}

      iex> create_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subscription(attrs \\ %{}) do
    %Subscription{}
    |> Subscription.changeset(attrs)
    |> Repo.insert()
    |> publish_subscription_created()
  end

  def publish_subscription_created({:ok, subscription}) do
    PubSub.broadcast(ER.PubSub, "subscription:created", {:subscription_created, subscription.id})
    {:ok, subscription}
  end

  def publish_subscription_created(result) do
    result
  end

  def publish_subscription_deleted({:ok, subscription}) do
    PubSub.broadcast(ER.PubSub, "subscription:deleted", {:subscription_deleted, subscription.id})
    {:ok, subscription}
  end

  def publish_subscription_deleted(result) do
    result
  end

  @doc """
  Updates a subscription.

  ## Examples

      iex> update_subscription(subscription, %{field: new_value})
      {:ok, %Subscription{}}

      iex> update_subscription(subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a subscription.

  ## Examples

      iex> delete_subscription(subscription)
      {:ok, %Subscription{}}

      iex> delete_subscription(subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_subscription(%Subscription{} = subscription) do
    Repo.delete(subscription)
    |> publish_subscription_deleted()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking subscription changes.

  ## Examples

      iex> change_subscription(subscription)
      %Ecto.Changeset{data: %Subscription{}}

  """
  def change_subscription(%Subscription{} = subscription, attrs \\ %{}) do
    Subscription.changeset(subscription, attrs)
  end

  alias ER.Subscriptions.Delivery

  @doc """
  Returns the list of deliveries.

  ## Examples

      iex> list_deliveries()
      [%Delivery{}, ...]

  """
  def list_deliveries do
    Repo.all(Delivery)
  end

  @doc """
  Gets a single delivery.

  Raises `Ecto.NoResultsError` if the Delivery does not exist.

  ## Examples

      iex> get_delivery!(123)
      %Delivery{}

      iex> get_delivery!(456)
      ** (Ecto.NoResultsError)

  """
  def get_delivery!(id), do: Repo.get!(Delivery, id)

  @doc """
  Creates a delivery.

  ## Examples

      iex> create_delivery(%{field: value})
      {:ok, %Delivery{}}

      iex> create_delivery(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_delivery(attrs \\ %{}) do
    %Delivery{}
    |> Delivery.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a delivery.

  ## Examples

      iex> update_delivery(delivery, %{field: new_value})
      {:ok, %Delivery{}}

      iex> update_delivery(delivery, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_delivery(%Delivery{} = delivery, attrs) do
    delivery
    |> Delivery.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a delivery.

  ## Examples

      iex> delete_delivery(delivery)
      {:ok, %Delivery{}}

      iex> delete_delivery(delivery)
      {:error, %Ecto.Changeset{}}

  """
  def delete_delivery(%Delivery{} = delivery) do
    Repo.delete(delivery)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking delivery changes.

  ## Examples

      iex> change_delivery(delivery)
      %Ecto.Changeset{data: %Delivery{}}

  """
  def change_delivery(%Delivery{} = delivery, attrs \\ %{}) do
    Delivery.changeset(delivery, attrs)
  end
end
