defmodule ER.PrunersTest do
  use ER.DataCase

  alias ER.Pruners
  alias ER.Pruners.Pruner
  import ER.Factory

  setup do
    {:ok, topic} = ER.Events.create_topic(%{name: "metrics"})

    {:ok, topic: topic}
  end

  describe "pruners" do
    @invalid_attrs %{name: nil, config: nil, query: nil}

    test "list_pruners/0 returns all pruners" do
      pruner = insert(:pruner)
      assert Enum.map(Pruners.list_pruners(), & &1.id) == [pruner.id]
    end

    test "get_pruner!/1 returns the pruner with given id" do
      pruner = insert(:pruner)
      assert Pruners.get_pruner!(pruner.id).id == pruner.id
    end

    test "create_pruner/1 with valid data creates a pruner", %{topic: topic} do
      valid_attrs = %{
        name: "some name",
        config: %{},
        query: "some query",
        type: :time,
        topic_name: topic.name
      }

      assert {:ok, %Pruner{} = pruner} = Pruners.create_pruner(valid_attrs)
      assert pruner.name == "some name"
      assert pruner.config == %{}
      assert pruner.query == "some query"
    end

    test "create_pruner/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Pruners.create_pruner(@invalid_attrs)
    end

    test "update_pruner/2 with valid data updates the pruner" do
      pruner = insert(:pruner)
      update_attrs = %{name: "some updated name", config: %{}, query: "some updated query"}

      assert {:ok, %Pruner{} = pruner} = Pruners.update_pruner(pruner, update_attrs)
      assert pruner.name == "some updated name"
      assert pruner.config == %{}
      assert pruner.query == "some updated query"
    end

    test "update_pruner/2 with invalid data returns error changeset" do
      pruner = insert(:pruner)
      assert {:error, %Ecto.Changeset{}} = Pruners.update_pruner(pruner, @invalid_attrs)
      assert pruner.id == Pruners.get_pruner!(pruner.id).id
    end

    test "delete_pruner/1 deletes the pruner" do
      pruner = insert(:pruner)
      assert {:ok, %Pruner{}} = Pruners.delete_pruner(pruner)
      assert_raise Ecto.NoResultsError, fn -> Pruners.get_pruner!(pruner.id) end
    end

    test "change_pruner/1 returns a pruner changeset" do
      pruner = insert(:pruner)
      assert %Ecto.Changeset{} = Pruners.change_pruner(pruner)
    end
  end
end
