defmodule InventorySyncWeb.LayoutsTest do
  use InventorySyncWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias InventorySyncWeb.Layouts

  test "renders collapse toggle and dropdowns" do
    html =
      render_component(&Layouts.app/1, %{
        flash: %{},
        current_scope: nil,
        current_path: "/",
        inner_content: []
      })

    assert html =~ "id=\"app-root\""
    assert html =~ "sidebar:toggle"
    assert html =~ "hero-bell"
    assert html =~ "Admin User"
  end
end
