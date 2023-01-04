defmodule ER.Events.SchemaTest do
  use ER.DataCase
  doctest ER.Events.Schema

  describe "build_create_topic_event_table_query!/1" do
    test "returns a query that creates a topic event table" do
      assert ER.Events.Schema.build_create_topic_event_table_query("users") == """
             CREATE TABLE users_events ( LIKE events INCLUDING ALL );
             """
    end
  end

  describe "build_fk_topic_event_table_query/1" do
    test "returns a query that creates a topic event table" do
      assert ER.Events.Schema.build_fk_topic_event_table_query("users") == """
             ALTER TABLE users_events ADD CONSTRAINT \"users_events_topic_name_fkey\" FOREIGN KEY (topic_name) REFERENCES topics(name);
             """
    end
  end

  describe "build_drop_topic_event_table_query/1" do
    test "returns a query that drops a topic event table" do
      assert ER.Events.Schema.build_drop_topic_event_table_query("users") == """
             DROP TABLE IF EXISTS users_events;
             """
    end
  end

  describe "build_create_topic_delivery_table_query!/1" do
    test "returns a query that creates a topic delivery table" do
      assert ER.Events.Schema.build_create_topic_delivery_table_query("users") == """
             CREATE TABLE users_deliveries ( LIKE deliveries INCLUDING ALL );
             """
    end
  end

  describe "build_drop_topic_delivery_table_query/1" do
    test "returns a query that drops a topic delivery table" do
      assert ER.Events.Schema.build_drop_topic_delivery_table_query("users") == """
             DROP TABLE IF EXISTS users_deliveries;
             """
    end
  end
end
