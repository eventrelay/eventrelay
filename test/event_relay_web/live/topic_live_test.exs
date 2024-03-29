defmodule ERWeb.TopicLiveTest do
  use ERWeb.ConnCase

  import Phoenix.LiveViewTest
  import ER.Factory

  @create_attrs %{name: "some name"}
  @invalid_attrs %{name: nil}

  defp create_topic(_) do
    {:ok, topic} = ER.Events.create_topic(params_for(:topic))
    %{topic: topic}
  end

  setup [:register_and_log_in_user]

  describe "Index" do
    setup [:create_topic]

    test "lists all topics", %{conn: conn, topic: topic} do
      {:ok, _index_live, html} = live(conn, ~p"/topics")

      assert html =~ "Listing Topics"
      assert html =~ topic.name
    end

    test "saves new topic", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/topics")

      assert index_live |> element("a", "New Topic") |> render_click() =~
               "New Topic"

      assert_patch(index_live, ~p"/topics/new")

      assert index_live
             |> form("#topic-form", topic: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#topic-form", topic: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/topics")

      assert html =~ "Topic created successfully"
      assert html =~ "some_name"
    end

    test "deletes topic in listing", %{conn: conn, topic: topic} do
      {:ok, index_live, _html} = live(conn, ~p"/topics")

      assert index_live |> element("#topics-#{topic.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#topic-#{topic.id}")
    end
  end

  describe "Show" do
    setup [:create_topic]

    test "displays topic", %{conn: conn, topic: topic} do
      {:ok, _show_live, html} = live(conn, ~p"/topics/#{topic}")

      assert html =~ "Show Topic"
      assert html =~ topic.name
    end
  end
end
