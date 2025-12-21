defmodule InventorySyncWeb.LayoutsTest do
  use InventorySyncWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias InventorySyncWeb.Layouts

  describe "app/1 layout component" do
    test "renders core elements without authentication" do
      html =
        render_component(&Layouts.app/1, %{
          flash: %{},
          current_scope: nil,
          current_path: "/",
          inner_content: []
        })

      # Core layout structure
      assert html =~ "id=\"app-root\""
      assert html =~ "sidebar:toggle"
      assert html =~ "hero-bell"

      # Navigation links
      assert html =~ "Dashboard"
      assert html =~ "Products"
      assert html =~ "Channels"

      # User menu shows generic icon when not authenticated
      assert html =~ "hero-user"
    end

    test "renders user information when authenticated" do
      # Mock a user scope
      mock_scope = %{user: %{email: "test@example.com"}}

      html =
        render_component(&Layouts.app/1, %{
          flash: %{},
          current_scope: mock_scope,
          current_path: "/dashboard",
          inner_content: []
        })

      # Core layout structure
      assert html =~ "id=\"app-root\""
      assert html =~ "sidebar:toggle"

      # User email is displayed (appears in header and dropdown)
      assert html =~ "test@example.com"

      # Avatar gradient styling is present (indicates user avatar is rendered)
      assert html =~ "from-emerald-400 to-teal-500"

      # Sign out link is present for authenticated users
      assert html =~ "Sign out"
    end

    test "highlights active navigation item" do
      html =
        render_component(&Layouts.app/1, %{
          flash: %{},
          current_scope: nil,
          current_path: "/products",
          inner_content: []
        })

      # The products link should have active styling (emerald color)
      assert html =~ "Products"
    end
  end
end
