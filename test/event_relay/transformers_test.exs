defmodule ER.TransformersTest do
  use ER.DataCase
  import ER.Factory
  alias ER.Transformers

  describe "factory/1" do
    setup do
      source = insert(:source)
      {:ok, source: source}
    end

    test "return lua transformer", %{source: source} do
      transformer =
        insert(:transformer,
          script: "",
          source: source,
          type: :lua,
          return_type: :map
        )

      assert %Transformers.LuaTransformer{} = Transformers.factory(transformer)
    end

    test "return liquid transformer", %{source: source} do
      transformer =
        insert(:transformer,
          script: "",
          source: source,
          type: :liquid,
          return_type: :map
        )

      assert %Transformers.LiquidTransformer{} = Transformers.factory(transformer)
    end
  end

  describe "transformers" do
    alias ER.Transformers.Transformer

    @invalid_attrs %{script: nil, source_id: nil, destination_id: nil}

    test "list_transformers/0 returns all transformers" do
      transformer = insert(:transformer)
      assert Enum.map(Transformers.list_transformers(), & &1.id) == [transformer.id]
    end

    test "get_transformer!/1 returns the transformer with given id" do
      transformer = insert(:transformer)
      assert Transformers.get_transformer!(transformer.id).id == transformer.id
    end

    test "create_transformer/1 with valid data creates a transformer" do
      source = insert(:source)
      valid_attrs = %{script: "some script", return_type: :map, source_id: source.id}

      assert {:ok, %Transformer{} = transformer} = Transformers.create_transformer(valid_attrs)
      assert transformer.script == "some script"
      assert transformer.return_type == :map
      assert transformer.source_id == source.id
    end

    test "create_transformer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{errors: errors}} =
               Transformers.create_transformer(@invalid_attrs)

      assert [
               script: {"can't be blank", [validation: :required]},
               return_type: {"can't be blank", [validation: :required]},
               destination_id: {"must select either a source or destination", []}
             ] == errors
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
