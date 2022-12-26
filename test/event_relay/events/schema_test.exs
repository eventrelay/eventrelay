defmodule ER.Events.SchemaTest do
  use ER.DataCase
  doctest ER.Events.Schema

  describe "build_create_topic_event_table_query/1" do
    test "returns a query that creates a topic event table" do
      assert ER.Events.Schema.build_create_topic_event_table_query("users") == """
             CREATE TABLE `users_events` AS SELECT * FROM `events`;
             """
    end
  end

  describe "build_drop_topic_event_table_query/1" do
    test "returns a query that drops a topic event table" do
      assert ER.Events.Schema.build_drop_topic_event_table_query("users") == """
             DROP TABLE `users_events`;
             """
    end
  end
end
