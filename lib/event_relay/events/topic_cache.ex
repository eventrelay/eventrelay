defmodule ER.Events.TopicCache do
  use Nebulex.Cache,
    otp_app: :event_relay,
    adapter: Nebulex.Adapters.Horde,
    horde: [
      members: :auto,
      process_redistribution: :passive
    ]

  @event_schema_ttl 5 * 60_000

  def fetch_event_schema_for_topic_and_event(topic_name, event_name)
      when is_binary(topic_name) and is_binary(event_name) do
    key = "event_schema:#{topic_name}:#{event_name}"

    event_schema = get(key)

    if event_schema do
      event_schema
    else
      try do
        topic = ER.Events.get_topic_by_name(topic_name)
        event_config = Enum.find(topic.event_configs, fn config -> config.name == event_name end)

        if event_config do
          event_schema =
            Jason.decode!(event_config.schema)

          put(key, event_schema, ttl: @event_schema_ttl)
          event_schema
        else
          nil
        end
      rescue
        _ -> nil
      end
    end
  end

  def fetch_event_schema_for_topic_and_event(_, _), do: nil
end
