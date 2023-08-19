defmodule ERWeb.MetricLiveTest do
  use ERWeb.ConnCase

  import Phoenix.LiveViewTest
  import ER.Factory

  @create_attrs %{
    field_path: "some field_path",
    name: "some name",
    type: :sum
  }
  @update_attrs %{
    field_path: "some updated field_path",
    name: "some updated name",
    type: :sum
  }
  @invalid_attrs %{field_path: nil, name: nil, type: :sum}

  defp create_metric(_) do
    metric = insert(:metric)
    %{metric: metric}
  end

  setup [:register_and_log_in_user]

  describe "Index" do
    setup [:create_metric]

    test "lists all metrics", %{conn: conn, metric: metric} do
      {:ok, _index_live, html} = live(conn, ~p"/metrics")

      assert html =~ "Listing Metrics"
      assert html =~ metric.field_path
    end

    test "saves new metric", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/metrics")

      assert index_live |> element("a", "New Metric") |> render_click() =~
               "New Metric"

      assert_patch(index_live, ~p"/metrics/new")

      assert index_live
             |> form("#metric-form", metric: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#metric-form", metric: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/metrics")

      html = render(index_live)
      assert html =~ "Metric created successfully"
      assert html =~ "some field_path"
    end

    test "updates metric in listing", %{conn: conn, metric: metric} do
      {:ok, index_live, _html} = live(conn, ~p"/metrics")

      assert index_live |> element("#metrics-#{metric.id} a", "Edit") |> render_click() =~
               "Edit Metric"

      assert_patch(index_live, ~p"/metrics/#{metric}/edit")

      assert index_live
             |> form("#metric-form", metric: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#metric-form", metric: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/metrics")

      html = render(index_live)
      assert html =~ "Metric updated successfully"
      assert html =~ "some updated field_path"
    end

    test "deletes metric in listing", %{conn: conn, metric: metric} do
      {:ok, index_live, _html} = live(conn, ~p"/metrics")

      assert index_live |> element("#metrics-#{metric.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#metrics-#{metric.id}")
    end
  end

  describe "Show" do
    setup [:create_metric]

    test "displays metric", %{conn: conn, metric: metric} do
      {:ok, _show_live, html} = live(conn, ~p"/metrics/#{metric}")

      assert html =~ "Show Metric"
      assert html =~ metric.field_path
    end

    test "updates metric within modal", %{conn: conn, metric: metric} do
      {:ok, show_live, _html} = live(conn, ~p"/metrics/#{metric}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Metric"

      assert_patch(show_live, ~p"/metrics/#{metric}/show/edit")

      assert show_live
             |> form("#metric-form", metric: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#metric-form", metric: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/metrics/#{metric}")

      html = render(show_live)
      assert html =~ "Metric updated successfully"
      assert html =~ "some updated field_path"
    end
  end
end
