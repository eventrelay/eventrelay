defmodule ER.Transformers.LiquidTransformerTest do
  use ER.DataCase
  import ER.Factory

  setup do
    source = insert(:source)

    transformer =
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
        source: source,
        return_type: :map
      )

    {:ok, transformer: transformer, source: source}
  end

  describe "perform/2" do
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
                 %ER.Transformers.LiquidTransformer{transformer: transformer},
                 message: message,
                 context: context
               )
    end
  end
end
