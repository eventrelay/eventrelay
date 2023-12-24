defmodule ER.SourcesTest do
  use ER.DataCase

  import ER.Factory
  alias ER.Sources

  describe "sources" do
    setup do
      topic = insert(:topic)

      {:ok, topic: topic}
    end

    alias ER.Sources.Source

    @invalid_attrs %{"config" => nil, "type" => nil}

    test "list_sources/0 returns all sources" do
      source = insert(:source)
      assert Enum.map(Sources.list_sources(), & &1.id) == [source.id]
    end

    test "get_source!/1 returns the source with given id" do
      source = insert(:source)
      assert Sources.get_source!(source.id).id == source.id
    end

    test "create_source/1 with valid data creates a source", %{topic: topic} do
      valid_attrs = %{
        "config" => %{},
        "type" => :webhook,
        "topic_name" => topic.name,
        "source" => "Webhook"
      }

      assert {:ok, %Source{} = source} = Sources.create_source(valid_attrs)
      assert source.config == %{}
      assert source.type == :webhook
    end

    test "create_source/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sources.create_source(@invalid_attrs)
    end

    test "update_source/2 with valid data updates the source" do
      source = insert(:source)

      update_attrs = %{
        "config" => %{},
        "type" => :webhook
      }

      assert {:ok, %Source{} = source} = Sources.update_source(source, update_attrs)
      assert source.config == %{}
      assert source.type == :webhook
    end

    test "update_source/2 with invalid data returns error changeset" do
      source = insert(:source)
      assert {:error, %Ecto.Changeset{}} = Sources.update_source(source, @invalid_attrs)
      assert source.id == Sources.get_source!(source.id).id
    end

    test "delete_source/1 deletes the source" do
      source = insert(:source)
      assert {:ok, %Source{}} = Sources.delete_source(source)
      assert_raise Ecto.NoResultsError, fn -> Sources.get_source!(source.id) end
    end

    test "change_source/1 returns a source changeset" do
      source = insert(:source)
      assert %Ecto.Changeset{} = Sources.change_source(source)
    end
  end
end
