defmodule ERWeb.EventJSON do
  alias ER.Events.Event

  alias ER.Events.Topic

  @doc """
  Renders a list of events.
  """
  def index(%{events: events}) do
    %{data: for(event <- events, do: data(event))}
  end

  def errors(%{errors: errors}) do
    %{errors: errors}
  end

  @doc """
  Renders a single event.
  """
  def show(%{event: event}) do
    %{data: data(event)}
  end

  defp data(%Event{} = event) do
    occurred_at =
      if ER.empty?(event.occurred_at) do
        ""
      else
        DateTime.to_iso8601(event.occurred_at)
      end

    topic = Topic.build_topic(event.topic_name, event.topic_identifier)

    %{
      id: event.id,
      name: event.name,
      topic: topic,
      source: event.source,
      group_key: event.group_key,
      reference_key: event.reference_key,
      trace_key: event.trace_key,
      data: event.data,
      prev_id: event.prev_id,
      context: event.context,
      occurred_at: occurred_at,
      offset: event.offset,
      user_id: event.user_id,
      anonymous_id: event.anonymous_id,
      errors: event.errors
    }
  end
end
