defmodule ER.Transformers.LuaTransformerTest do
  use ER.DataCase
  import ER.Factory

  setup do
    source = insert(:source)

    transformer =
      insert(:transformer,
        script:
          "return {event = { topic_name = context.topic_name, data = message.event_data, name = message.event_name, source = context.source}}",
        source: source,
        type: :lua,
        return_type: :map
      )

    {:ok, transformer: transformer, source: source}
  end

  describe "to_map/2" do
    test "handles nested maps", %{transformer: transformer} do
      return = [
        {"event",
         [
           {"data", [{"user", "themusicman"}]},
           {"name", "users.updated"},
           {"source", "GooglePubsub"},
           {"topic_name", "users"}
         ]}
      ]

      assert %{
               "event" => %{
                 "data" => %{"user" => "themusicman"},
                 "name" => "users.updated",
                 "source" => "GooglePubsub",
                 "topic_name" => "users"
               }
             } == ER.Transformers.LuaTransformer.return(return, transformer)
    end
  end

  describe "run/3" do
    test "returns data for an event", %{transformer: transformer} do
      message = %{
        "event_data" => %{"user" => "themusicman"},
        "event_name" => "users.updated"
      }

      context = %{
        "source" => "GooglePubsub",
        "topic_name" => "users"
      }

      assert %{
               "event" => %{
                 "data" => %{"user" => "themusicman"},
                 "name" => "users.updated",
                 "source" => "GooglePubsub",
                 "topic_name" => "users"
               }
             } ==
               ER.Transformers.Transformation.perform(
                 %ER.Transformers.LuaTransformer{transformer: transformer},
                 message: message,
                 context: context
               )
    end
  end
end
