defmodule ER.Destinations.Pipeline.File.Format.JsonlTest do
  use ER.DataCase
  import ER.Test.Setups
  import ER.Test.Helpers
  import ER.Factory

  describe "encode/3" do
    setup [:setup_topic, :setup_messages]

    test "encodes events to jsonl", %{messages: messages} do
      encoder = %ER.Destinations.File.Format.Jsonl{}

      destination = insert(:destination)

      {_encoder, jsonl} = ER.Destinations.File.Format.encode(encoder, messages, destination)

      parsed_jsonl = parse_jsonl(jsonl)

      assert Enum.count(parsed_jsonl) == 2
      first_event = List.first(messages) |> then(& &1.data)

      first_parsed_event = List.first(parsed_jsonl)
      assert first_event.id == first_parsed_event["id"]
    end

    test "transforms and encodes events to jsonl", %{messages: messages} do
      first_event = List.first(messages) |> then(& &1.data)

      encoder = %ER.Destinations.File.Format.Jsonl{}

      destination = insert(:destination)

      insert(:transformer,
        script: """
        {
           "event": {
              "data": {{message.event_data | json}},
              "name": "{{message.event_name}}",
              "source": "{{context.source}}",
              "topic_name": "{{context.topic_name}}"
          }
        }
        """,
        type: :liquid,
        destination: destination,
        return_type: :map,
        query: "topic_name == '#{first_event.topic_name}'"
      )

      {_encoder, jsonl} = ER.Destinations.File.Format.encode(encoder, messages, destination)

      parsed_jsonl = parse_jsonl(jsonl)

      assert Enum.count(parsed_jsonl) == 2

      first_parsed_event = List.first(parsed_jsonl)
      assert first_event.id == first_parsed_event["id"]
    end
  end
end
