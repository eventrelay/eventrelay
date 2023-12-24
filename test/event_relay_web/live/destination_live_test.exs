defmodule ERWeb.DestinationLiveTest do
  use ERWeb.ConnCase

  import Phoenix.LiveViewTest

  import ER.Factory

  @create_attrs %{
    name: "some_name",
    topic_name: "test",
    destination_type: "webhook"
  }
  @update_attrs %{
    name: "some_updated_name",
    topic_name: "test",
    destination_type: "webhook"
  }
  @invalid_attrs %{
    name: nil,
    topic_name: nil,
    destination_type: nil
  }

  defp create_destination(_) do
    topic = insert(:topic, name: "test")
    destination = insert(:destination, topic: topic)
    %{destination: destination, topic: topic}
  end

  setup [:register_and_log_in_user]

  describe "Index" do
    setup [:create_destination]

    test "lists all destinations", %{conn: conn, destination: destination} do
      {:ok, _index_live, html} = live(conn, ~p"/destinations")

      assert html =~ "Listing Destinations"
      assert html =~ destination.name
    end

    test "saves new destination", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/destinations")

      assert index_live |> element("a", "New Destination") |> render_click() =~
               "New Destination"

      assert_patch(index_live, ~p"/destinations/new")

      assert index_live
             |> form("#destination-form", destination: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#destination-form", destination: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/destinations")

      assert html =~ "Destination created successfully"
      assert html =~ "some_name"
    end

    test "updates destination in listing", %{conn: conn, destination: destination} do
      {:ok, index_live, _html} = live(conn, ~p"/destinations")

      assert index_live
             |> element("#destinations-#{destination.id} a", "Edit")
             |> render_click() =~
               "Edit Destination"

      assert_patch(index_live, ~p"/destinations/#{destination}/edit")

      assert index_live
             |> form("#destination-form", destination: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#destination-form", destination: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/destinations")

      assert html =~ "Destination updated successfully"
      assert html =~ "some_updated_name"
    end

    test "deletes destination in listing", %{conn: conn, destination: destination} do
      {:ok, index_live, _html} = live(conn, ~p"/destinations")

      assert index_live
             |> element("#destinations-#{destination.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#destination-#{destination.id}")
    end
  end

  describe "Show" do
    setup [:create_destination]

    test "displays destination", %{conn: conn, destination: destination} do
      {:ok, _show_live, html} = live(conn, ~p"/destinations/#{destination}")

      assert html =~ "Show Destination"
      assert html =~ destination.name
    end

    test "updates destination within modal", %{conn: conn, destination: destination} do
      {:ok, show_live, _html} = live(conn, ~p"/destinations/#{destination}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Destination"

      assert_patch(show_live, ~p"/destinations/#{destination}/show/edit")

      assert show_live
             |> form("#destination-form", destination: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#destination-form", destination: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/destinations/#{destination}")

      assert html =~ "Destination updated successfully"
      assert html =~ "some_updated_name"
    end
  end
end
