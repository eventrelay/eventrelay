defmodule ERWeb.ErrorJSONTest do
  use ERWeb.ConnCase, async: true

  test "renders 404" do
    assert ERWeb.ErrorJSON.render("404.json", %{}) == %{errors: ["Not Found"]}
  end

  test "renders 500" do
    assert ERWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: ["Internal Server Error"]}
  end
end
