defmodule ER.Destinations.Pipeline.File.Format.JsonlTest do
  use ER.DataCase
  import ER.Test.Setups
  import ER.Test.Helpers

  describe "encode/3" do
    setup [:setup_topic, :setup_messages]

    test "encodes events to jsonl", %{messages: messages} do
      encoder = %ER.Destinations.File.Format.Jsonl{}

      {_encoder, jsonl} = ER.Destinations.File.Format.encode(encoder, messages)

      parsed_jsonl = parse_jsonl(jsonl)

      assert Enum.count(parsed_jsonl) == 2
      first_event = List.first(messages) |> then(& &1.data)

      first_parsed_event = List.first(parsed_jsonl)
      assert first_event.id == first_parsed_event["id"]
    end
  end
end
