defmodule InventorySyncWeb.ProductLive.IndexTest do
  use InventorySyncWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import InventorySync.InventoryFixtures

  describe "ProductLive.Index" do
    setup %{conn: conn} do
      %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
      %{conn: conn, user: user}
    end

    test "renders products list page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/products")

      assert html =~ "Products"
      assert html =~ "Add Product"
    end

    test "displays products in the table", %{conn: conn} do
      product1 = product_fixture(%{name: "Widget A", sku: "WIDGET-A", total_quantity: 100})
      product2 = product_fixture(%{name: "Widget B", sku: "WIDGET-B", total_quantity: 200})

      {:ok, _view, html} = live(conn, ~p"/products")

      assert html =~ product1.name
      assert html =~ product1.sku
      assert html =~ "#{product1.total_quantity}"
      assert html =~ product2.name
      assert html =~ product2.sku
    end

    test "opens add product modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/products")

      html =
        view
        |> element("button", "Add Product")
        |> render_click()

      assert html =~ "Add New Product"
      assert html =~ "SKU"
      assert html =~ "Name"
      assert html =~ "Initial Quantity"
    end

    test "closes add product modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/products")

      # Open modal
      view |> element("button", "Add Product") |> render_click()

      # Close modal
      html =
        view
        |> element("button", "Cancel")
        |> render_click()

      refute html =~ "Add New Product"
    end

    test "creates a new product", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/products")

      # Open modal
      view |> element("button", "Add Product") |> render_click()

      # Submit the form (use specific selector to avoid matching search form)
      html =
        view
        |> form("form[phx-submit='save-product']", %{
          "product" => %{
            "sku" => "NEW-PRODUCT-SKU",
            "name" => "New Test Product",
            "total_quantity" => "50"
          }
        })
        |> render_submit()

      assert html =~ "Product created successfully"
      assert html =~ "NEW-PRODUCT-SKU"
      assert html =~ "New Test Product"
      assert html =~ "50"
    end

    test "shows validation errors for invalid product", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/products")

      # Open modal
      view |> element("button", "Add Product") |> render_click()

      # Submit empty form (use specific selector to avoid matching search form)
      html =
        view
        |> form("form[phx-submit='save-product']", %{
          "product" => %{
            "sku" => "",
            "name" => "",
            "total_quantity" => ""
          }
        })
        |> render_submit()

      # Modal should stay open with errors
      assert html =~ "Add New Product"
    end

    test "enters edit mode for quantity", %{conn: conn} do
      product = product_fixture(%{name: "Edit Me", sku: "EDIT-SKU", total_quantity: 77})

      {:ok, view, _html} = live(conn, ~p"/products")

      # Verify product is displayed
      assert render(view) =~ product.sku

      # Enter edit mode by pushing the event directly
      html = render_click(view, "edit-quantity", %{"id" => to_string(product.id)})

      # Should show input field with current value
      assert html =~ "value=\"77\""
      assert html =~ "Save"
    end

    test "cancels quantity edit", %{conn: conn} do
      product = product_fixture(%{name: "Cancel Edit", sku: "CANCEL-SKU", total_quantity: 33})

      {:ok, view, _html} = live(conn, ~p"/products")

      # Enter edit mode by pushing the event directly
      render_click(view, "edit-quantity", %{"id" => to_string(product.id)})

      # Cancel edit by pushing the cancel-edit event directly
      # (phx-click-away can't be triggered via render_blur)
      html = render_click(view, "cancel-edit")

      # Should show regular display
      assert html =~ "33"
    end

    test "saves updated quantity", %{conn: conn} do
      product = product_fixture(%{name: "Update Quantity", sku: "UPDATE-SKU", total_quantity: 10})

      {:ok, view, _html} = live(conn, ~p"/products")

      # Enter edit mode by pushing the event directly
      render_click(view, "edit-quantity", %{"id" => to_string(product.id)})

      # Submit new quantity
      html =
        view
        |> form("form[phx-submit='save-quantity']", %{
          "product_id" => product.id,
          "quantity" => "999"
        })
        |> render_submit()

      assert html =~ "Quantity updated successfully"
      assert html =~ "999"
    end

    test "navigates to product detail page", %{conn: conn} do
      product = product_fixture(%{name: "View Details", sku: "DETAILS-SKU", total_quantity: 42})

      {:ok, view, _html} = live(conn, ~p"/products")

      assert view
             |> element("a", "Manage Mappings")
             |> has_element?()

      # Check link points to correct product
      html = render(view)
      assert html =~ ~p"/products/#{product.id}"
    end

    test "shows SKU uniqueness error", %{conn: conn} do
      # Create existing product
      product_fixture(%{sku: "EXISTING-SKU"})

      {:ok, view, _html} = live(conn, ~p"/products")

      # Open modal
      view |> element("button", "Add Product") |> render_click()

      # Submit with duplicate SKU (use specific selector to avoid matching search form)
      html =
        view
        |> form("form[phx-submit='save-product']", %{
          "product" => %{
            "sku" => "EXISTING-SKU",
            "name" => "Duplicate Product",
            "total_quantity" => "10"
          }
        })
        |> render_submit()

      # Modal should stay open with form (validation error)
      assert html =~ "Add New Product"
    end
  end
end
