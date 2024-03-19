defmodule ERWeb.EventLiveTest do
  use ERWeb.ConnCase

  import Phoenix.LiveViewTest
  import ER.Factory

  # @create_attrs %{
  #   context_json: "{\"foo\":\"bar\"}",
  #   data_json: "{\"foo\":\"bar\"}",
  #   name: "some name",
  #   occurred_at: "2022-12-21T18:27:00Z",
  #   source: "some source",
  #   topic_name: "test"
  # }
  # @invalid_attrs %{
  #   context_json: "",
  #   data_json: "",
  #   name: nil,
  #   occurred_at: nil,
  #   source: nil,
  #   topic_name: nil
  # }

  defp create_event_and_topic(_) do
    topic = insert(:topic, name: "test")
    ER.Events.Event.create_table!(topic)
    {:ok, event} = ER.Events.create_event_for_topic(params_for(:event, topic: topic))

    on_exit(fn ->
      ER.Events.Event.drop_table!(topic)
    end)

    %{event: event, topic: topic}
  end

  setup [:register_and_log_in_user]

  describe "Index" do
    setup [:create_event_and_topic]

    test "lists all events", %{conn: conn, event: event, topic: topic} do
      {:ok, _index_live, html} = live(conn, ~p"/topics/#{topic}/events")

      assert html =~ "Listing Events"
      assert html =~ event.name
    end

    # test "saves new event", %{conn: conn, topic: topic} do
    #   {:ok, index_live, _html} = live(conn, ~p"/topics/#{topic}/events")
    #
    #   assert index_live |> element("a", "New Event") |> render_click() =~
    #            "New Event"
    #
    #   assert_patch(index_live, ~p"/topics/#{topic}/events/new")
    #
    #   assert index_live
    #          |> form("#event-form", event: @invalid_attrs)
    #          |> render_change() =~ "can&#39;t be blank"
    #
    #   {:ok, _, html} =
    #     index_live
    #     |> form("#event-form", event: @create_attrs)
    #     |> render_submit()
    #     |> follow_redirect(conn, ~p"/topics/#{topic}/events")
    #
    #   assert html =~ "Event created successfully"
    #   assert html =~ "some name"
    # end

    test "deletes event in listing", %{conn: conn, event: event, topic: topic} do
      {:ok, index_live, _html} = live(conn, ~p"/topics/#{topic}/events")

      assert index_live |> element("#events-#{event.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#event-#{event.id}")
    end
  end

  describe "Show" do
    setup [:create_event_and_topic]

    test "displays event", %{conn: conn, event: event, topic: topic} do
      {:ok, _show_live, html} = live(conn, ~p"/topics/#{topic}/events/#{event}")

      assert html =~ "Show Event"
      assert html =~ event.name
    end
  end
end
