defmodule ER.Events.EventTest do
  use ER.DataCase
  doctest ER.Events.Event

  alias ER.Events.Event
  import ER.Factory

  describe "table_name/1" do
    test "returns lowercase event table_name from on topic name" do
      assert "metrics_events" == ER.Events.Event.table_name("metrics")
      assert "metrics_events" == ER.Events.Event.table_name("Metrics")
    end
  end

  describe "signature/2" do
    test "returns a valid SHA256 HMAC for an event" do
      expected_hmac = "13ff62e206fe61ff15774a87bf10e8da5931f55426ef27735ee18ff44227b3d9"

      json =
        "{\"id\":\"85cddd1f-88b2-4cf7-818d-887ab9550647\",\"topic_name\":null,\"topic_identifier\":null,\"name\":\"some name\",\"data\":{},\"data_schema\":null,\"user_id\":null,\"anonymous_id\":null,\"occurred_at\":\"2022-12-21T18:27:00Z\",\"offset\":243,\"source\":\"some source\",\"context\":{},\"errors\":null,\"group_key\":null,\"reference_key\":null,\"trace_key\":null}"

      assert ER.Events.Event.signature(json, signing_secret: "testing123") == expected_hmac
    end

    test "returns a HMAC for an event" do
      event = insert(:event)

      expected_hmac = ER.Auth.hmac(value: Event.json_encode!(event), signing_secret: "testing123")

      assert ER.Events.Event.signature(event, signing_secret: "testing123") == expected_hmac
    end
  end
end
