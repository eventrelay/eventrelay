defmodule ER.SubscriptionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ER.Subscriptions` context.
  """

  @doc """
  Generate a subscription.
  """
  def subscription_fixture(attrs \\ %{}) do
    {:ok, subscription} =
      attrs
      |> Enum.into(%{
        name: "some name",
        offset: 42,
        ordered: true,
        pull: true,
        topic_name: "some topic_name"
      })
      |> ER.Subscriptions.create_subscription()

    subscription
  end

  @doc """
  Generate a delivery.
  """
  def delivery_fixture(attrs \\ %{}) do
    {:ok, delivery} =
      attrs
      |> Enum.into(%{
        attempts: []
      })
      |> ER.Subscriptions.create_delivery()

    delivery
  end
end
