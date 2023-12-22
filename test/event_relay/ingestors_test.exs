defmodule ER.IngestorsTest do
  use ER.DataCase

  import ER.Factory
  alias ER.Ingestors

  describe "ingestors" do
    setup do
      topic = insert(:topic)

      {:ok, topic: topic}
    end

    alias ER.Ingestors.Ingestor

    @invalid_attrs %{config: nil, type: nil}

    test "list_ingestors/0 returns all ingestors" do
      ingestor = insert(:ingestor)
      assert Enum.map(Ingestors.list_ingestors(), & &1.id) == [ingestor.id]
    end

    test "get_ingestor!/1 returns the ingestor with given id" do
      ingestor = insert(:ingestor)
      assert Ingestors.get_ingestor!(ingestor.id).id == ingestor.id
    end

    test "create_ingestor/1 with valid data creates a ingestor", %{topic: topic} do
      valid_attrs = %{
        config: %{},
        type: :webhook,
        topic_name: topic.name,
        source: "Webhook"
      }

      assert {:ok, %Ingestor{} = ingestor} = Ingestors.create_ingestor(valid_attrs)
      assert ingestor.config == %{}
      assert ingestor.type == :webhook
    end

    test "create_ingestor/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ingestors.create_ingestor(@invalid_attrs)
    end

    test "update_ingestor/2 with valid data updates the ingestor" do
      ingestor = insert(:ingestor)
      update_attrs = %{config: %{}, type: :webhook}

      assert {:ok, %Ingestor{} = ingestor} = Ingestors.update_ingestor(ingestor, update_attrs)
      assert ingestor.config == %{}
      assert ingestor.type == :webhook
    end

    test "update_ingestor/2 with invalid data returns error changeset" do
      ingestor = insert(:ingestor)
      assert {:error, %Ecto.Changeset{}} = Ingestors.update_ingestor(ingestor, @invalid_attrs)
      assert ingestor.id == Ingestors.get_ingestor!(ingestor.id).id
    end

    test "delete_ingestor/1 deletes the ingestor" do
      ingestor = insert(:ingestor)
      assert {:ok, %Ingestor{}} = Ingestors.delete_ingestor(ingestor)
      assert_raise Ecto.NoResultsError, fn -> Ingestors.get_ingestor!(ingestor.id) end
    end

    test "change_ingestor/1 returns a ingestor changeset" do
      ingestor = insert(:ingestor)
      assert %Ecto.Changeset{} = Ingestors.change_ingestor(ingestor)
    end
  end
end
