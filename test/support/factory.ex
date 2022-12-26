defmodule ER.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: ER.Repo

  def event_factory do
    %ER.Events.Event{
      context: %{},
      data: %{},
      name: "some name",
      occurred_at: ~U[2022-12-21 18:27:00Z],
      offset: Enum.random(0..9_999_999),
      source: "some source"
    }
  end

  def topic_factory do
    %ER.Events.Topic{
      name: "test"
    }
  end
end
