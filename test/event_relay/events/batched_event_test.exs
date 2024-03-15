defmodule ER.Events.BatchedEventTest do
  use ER.DataCase
  doctest ER.Events.BatchedEvent

  alias ER.Events.BatchedEvent

  describe "new_with_defaults/1" do
    setup do
      attrs =
        %{
          name: "user.created",
          source: "test",
          group_key: "group123",
          reference_key: "ref123",
          trace_key: "trace123",
          data_json: Jason.encode!(%{first_name: "Natalie"}),
          context: %{"ip_address" => "127.0.0.1"},
          available_at: DateTime.utc_now() |> DateTime.to_iso8601(),
          user_key: "user123",
          anonymous_key: "anon123",
          durable: true,
          verified: true,
          topic_name: "users",
          topic_identifier: nil,
          data_schema_json:
            Jason.encode!(%{
              "type" => "object",
              "properties" => %{
                "first_name" => %{
                  "type" => "string"
                }
              }
            }),
          prev_id: nil
        }

      {:ok, attrs: attrs}
    end

    test "returns map that can be used with insert_all", %{attrs: attrs} do
      attrs = BatchedEvent.new_with_defaults(attrs)

      %{
        data: %{"first_name" => "Natalie"},
        name: "user.created",
        context: %{"ip_address" => "127.0.0.1"},
        source: "test",
        topic_name: "users",
        topic_identifier: nil,
        group_key: "group123",
        reference_key: "ref123",
        trace_key: "trace123",
        user_key: "user123",
        anonymous_key: "anon123",
        verified: true,
        data_schema: %{
          "properties" => %{"first_name" => %{"type" => "string"}},
          "type" => "object"
        },
        prev_id: nil
      } = attrs

      assert attrs[:prev_id] == nil
      refute Map.has_key?(attrs, :data_json)
      refute Map.has_key?(attrs, :data_schema_json)
      refute Map.has_key?(attrs, :durable)

      assert Flamel.datetime?(attrs[:available_at])
      assert Flamel.datetime?(attrs[:occurred_at])
      assert Uniq.UUID.valid?(attrs[:id])
    end
  end
end
