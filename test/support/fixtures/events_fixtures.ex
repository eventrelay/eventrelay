defmodule ER.EventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ER.Events` context.
  """

  @doc """
  Generate a topic.
  """
  def topic_fixture(attrs \\ %{}) do
    {:ok, topic} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> ER.Events.create_topic()

    topic
  end
end
