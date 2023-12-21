defmodule ERWeb.PrunerLiveTest do
  use ERWeb.ConnCase

  import Phoenix.LiveViewTest
  import ER.Factory

  @create_attrs %{
    name: "some name",
    config_json: "{\"foo\": \"bar\"}",
    query: "some query",
    topic_name: "metrics",
    type: :count
  }
  @update_attrs %{
    name: "some updated name",
    config_json: "{\"foo\": \"bar\"}",
    query: "some updated query"
  }
  @invalid_attrs %{name: nil, config_json: "", query: nil}

  defp create_pruner_and_topic(_) do
    topic = insert(:topic, name: "metrics")
    ER.Events.Event.create_table!(topic)

    on_exit(fn ->
      ER.Events.Event.drop_table!(topic)
    end)

    pruner = insert(:pruner)
    %{pruner: pruner, topic: topic}
  end

  setup [:register_and_log_in_user]

  describe "Index" do
    setup [:create_pruner_and_topic]

    test "lists all pruners", %{conn: conn, pruner: pruner} do
      {:ok, _index_live, html} = live(conn, ~p"/pruners")

      assert html =~ "Listing Pruners"
      assert html =~ pruner.name
    end

    test "saves new pruner", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/pruners")

      assert index_live |> element("a", "New Pruner") |> render_click() =~
               "New Pruner"

      assert_patch(index_live, ~p"/pruners/new")

      assert index_live
             |> form("#pruner-form", pruner: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#pruner-form", pruner: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/pruners")

      html = render(index_live)
      assert html =~ "Pruner created successfully"
      assert html =~ "some name"
    end

    test "updates pruner in listing", %{conn: conn, pruner: pruner} do
      {:ok, index_live, _html} = live(conn, ~p"/pruners")

      assert index_live |> element("#pruners-#{pruner.id} a", "Edit") |> render_click() =~
               "Edit Pruner"

      assert_patch(index_live, ~p"/pruners/#{pruner}/edit")

      assert index_live
             |> form("#pruner-form", pruner: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#pruner-form", pruner: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/pruners")

      html = render(index_live)
      assert html =~ "Pruner updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes pruner in listing", %{conn: conn, pruner: pruner} do
      {:ok, index_live, _html} = live(conn, ~p"/pruners")

      assert index_live |> element("#pruners-#{pruner.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#pruners-#{pruner.id}")
    end
  end

  describe "Show" do
    setup [:create_pruner_and_topic]

    test "displays pruner", %{conn: conn, pruner: pruner} do
      {:ok, _show_live, html} = live(conn, ~p"/pruners/#{pruner}")

      assert html =~ "Show Pruner"
      assert html =~ pruner.name
    end

    test "updates pruner within modal", %{conn: conn, pruner: pruner} do
      {:ok, show_live, _html} = live(conn, ~p"/pruners/#{pruner}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Pruner"

      assert_patch(show_live, ~p"/pruners/#{pruner}/show/edit")

      assert show_live
             |> form("#pruner-form", pruner: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#pruner-form", pruner: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/pruners/#{pruner}")

      html = render(show_live)
      assert html =~ "Pruner updated successfully"
      assert html =~ "some updated name"
    end
  end
end
