defmodule ER.TopicTable do
  alias ER.Events.Topic

  @callback put_ecto_source(struct(), Topic.t() | Topic.topic_name()) :: struct()

  @callback table_name(Topic.t() | Topic.topic_name()) :: String.t()

  @callback create_queries(Topic.t() | Topic.topic_name()) :: [String.t()]

  @callback drop_queries(Topic.t() | Topic.topic_name()) :: [String.t()]

  @callback create_table!(Topic.t() | Topic.topic_name()) :: :ok

  @callback drop_table!(Topic.t() | Topic.topic_name()) :: :ok
end
