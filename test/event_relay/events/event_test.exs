defmodule ER.Events.EventTest do
  use ER.DataCase
  doctest ER.Events.Event

  import ER.Factory

  describe "signature/2" do
    test "returns a signature for an event" do
      event = insert(:event)

      json = ER.Events.Event.json_encode!(event)
      signature = ER.Auth.signature(value: json, signing_secret: "test123")

      assert ER.Events.Event.signature(event, signing_secret: "test123") == signature
    end
  end
end
