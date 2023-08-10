defmodule ER.TransformersTest do
  use ER.DataCase
  import ER.Factory
  alias ER.Transformers

  describe "to_map/2" do
    test "handles nested maps" do
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
             } == ER.Transformers.to_map(return)
    end
  end

  describe "run/3" do
    test "returns data for an event" do
      ingestor = insert(:ingestor)

      message = %{
        "event_data" => %{"user" => "themusicman"},
        "event_name" => "users.updated"
      }

      context = %{
        "source" => "GooglePubsub",
        "topic_name" => "users"
      }

      transformer =
        insert(:transformer,
          script:
            "return {event = { topic_name = context.topic_name, data = message.event_data, name = message.event_name, source = context.source}}",
          ingestor: ingestor,
          return_type: :map
        )

      assert %{
               "event" => %{
                 "data" => %{"user" => "themusicman"},
                 "name" => "users.updated",
                 "source" => "GooglePubsub",
                 "topic_name" => "users"
               }
             } == ER.Transformers.run(transformer, message: message, context: context)
    end
  end

  describe "transformers" do
    alias ER.Transformers.Transformer

    @invalid_attrs %{script: nil}

    test "list_transformers/0 returns all transformers" do
      transformer = insert(:transformer)
      assert Enum.map(Transformers.list_transformers(), & &1.id) == [transformer.id]
    end

    test "get_transformer!/1 returns the transformer with given id" do
      transformer = insert(:transformer)
      assert Transformers.get_transformer!(transformer.id).id == transformer.id
    end

    test "create_transformer/1 with valid data creates a transformer" do
      valid_attrs = %{script: "some script", return_type: :map}

      assert {:ok, %Transformer{} = transformer} = Transformers.create_transformer(valid_attrs)
      assert transformer.script == "some script"
      assert transformer.return_type == :map
    end

    test "create_transformer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Transformers.create_transformer(@invalid_attrs)
    end

    test "update_transformer/2 with valid data updates the transformer" do
      transformer = insert(:transformer)
      update_attrs = %{script: "some updated script", return_type: :map}

      assert {:ok, %Transformer{} = transformer} =
               Transformers.update_transformer(transformer, update_attrs)

      assert transformer.script == "some updated script"
    end

    test "update_transformer/2 with invalid data returns error changeset" do
      transformer = insert(:transformer)

      assert {:error, %Ecto.Changeset{}} =
               Transformers.update_transformer(transformer, @invalid_attrs)

      assert transformer.id == Transformers.get_transformer!(transformer.id).id
    end

    test "delete_transformer/1 deletes the transformer" do
      transformer = insert(:transformer)
      assert {:ok, %Transformer{}} = Transformers.delete_transformer(transformer)
      assert_raise Ecto.NoResultsError, fn -> Transformers.get_transformer!(transformer.id) end
    end

    test "change_transformer/1 returns a transformer changeset" do
      transformer = insert(:transformer)
      assert %Ecto.Changeset{} = Transformers.change_transformer(transformer)
    end
  end
end
