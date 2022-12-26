defmodule ER.EventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ER.Events` context.
  """

  @doc """
  Generate a event.
  """
  def event_fixture(attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{
        context: %{},
        data: %{},
        name: "some name",
        occurred_at: ~U[2022-12-21 18:27:00Z],
        offset: 42,
        source: "some source"
      })
      |> ER.Events.create_event()

    event
  end

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
