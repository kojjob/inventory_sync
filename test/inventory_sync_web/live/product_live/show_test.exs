defmodule InventorySyncWeb.ProductLive.ShowTest do
  use InventorySyncWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import InventorySync.InventoryFixtures

  describe "ProductLive.Show" do
    setup %{conn: conn} do
      %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
      product = product_fixture(%{name: "Test Product", sku: "TEST-SKU-001", total_quantity: 100})
      channel = channel_fixture(%{name: "Shopify Store", platform: :shopify})

      %{conn: conn, user: user, product: product, channel: channel}
    end

    test "renders product details", %{conn: conn, product: product} do
      {:ok, _view, html} = live(conn, ~p"/products/#{product.id}")

      assert html =~ product.name
      assert html =~ product.sku
      assert html =~ "#{product.total_quantity}"
      assert html =~ "Channel Mappings"
      assert html =~ "Add Channel Mapping"
    end

    test "shows empty state when no channel mappings exist", %{conn: conn, product: product} do
      {:ok, _view, html} = live(conn, ~p"/products/#{product.id}")

      assert html =~ "No channel mappings"
      assert html =~ "Get started by adding a channel mapping"
    end

    test "displays existing channel mappings", %{conn: conn, product: product, channel: channel} do
      inventory_item_fixture(%{
        product_id: product.id,
        channel_id: channel.id,
        platform_sku: "SHOP-12345",
        quantity: 50
      })

      {:ok, _view, html} = live(conn, ~p"/products/#{product.id}")

      assert html =~ channel.name
      assert html =~ "SHOP-12345"
      assert html =~ "50"
      refute html =~ "No channel mappings"
    end

    test "opens add mapping modal", %{conn: conn, product: product} do
      {:ok, view, _html} = live(conn, ~p"/products/#{product.id}")

      html = view
             |> element("button", "Add Channel Mapping")
             |> render_click()

      assert html =~ "Add Channel Mapping"
      assert html =~ "Link this product to a sales channel"
      assert html =~ "Select channel..."
    end

    test "closes add mapping modal", %{conn: conn, product: product} do
      {:ok, view, _html} = live(conn, ~p"/products/#{product.id}")

      # Open modal
      view |> element("button", "Add Channel Mapping") |> render_click()

      # Close modal
      html = view
             |> element("button", "Cancel")
             |> render_click()

      refute html =~ "Link this product to a sales channel"
    end

    test "adds a new channel mapping", %{conn: conn, product: product, channel: channel} do
      {:ok, view, _html} = live(conn, ~p"/products/#{product.id}")

      # Open modal
      view |> element("button", "Add Channel Mapping") |> render_click()

      # Submit the form (use specific phx-submit selector to avoid matching search form)
      html = view
             |> form("form[phx-submit='add-mapping']", %{
               "channel_id" => channel.id,
               "platform_sku" => "NEW-SKU-123",
               "quantity" => "75"
             })
             |> render_submit()

      assert html =~ "Channel mapping added successfully"
      assert html =~ channel.name
      assert html =~ "NEW-SKU-123"
      assert html =~ "75"
    end

    test "enters edit mode for a mapping", %{conn: conn, product: product, channel: channel} do
      inventory_item = inventory_item_fixture(%{
        product_id: product.id,
        channel_id: channel.id,
        platform_sku: "EDIT-SKU",
        quantity: 25
      })

      {:ok, view, _html} = live(conn, ~p"/products/#{product.id}")

      html = view
             |> element("button[phx-click='edit-mapping'][phx-value-id='#{inventory_item.id}']")
             |> render_click()

      # Should show form inputs with current values
      assert html =~ "value=\"EDIT-SKU\""
      assert html =~ "value=\"25\""
      assert html =~ "Save"
      assert html =~ "Cancel"
    end

    test "cancels edit mode", %{conn: conn, product: product, channel: channel} do
      inventory_item = inventory_item_fixture(%{
        product_id: product.id,
        channel_id: channel.id,
        platform_sku: "CANCEL-SKU",
        quantity: 30
      })

      {:ok, view, _html} = live(conn, ~p"/products/#{product.id}")

      # Enter edit mode
      view
      |> element("button[phx-click='edit-mapping'][phx-value-id='#{inventory_item.id}']")
      |> render_click()

      # Cancel edit
      html = view
             |> element("button[phx-click='cancel-edit']")
             |> render_click()

      # Should show regular display again (no form inputs)
      refute html =~ "value=\"CANCEL-SKU\""
      assert html =~ "CANCEL-SKU"
    end

    test "saves edited mapping", %{conn: conn, product: product, channel: channel} do
      inventory_item = inventory_item_fixture(%{
        product_id: product.id,
        channel_id: channel.id,
        platform_sku: "OLD-SKU",
        quantity: 10
      })

      {:ok, view, _html} = live(conn, ~p"/products/#{product.id}")

      # Enter edit mode
      view
      |> element("button[phx-click='edit-mapping'][phx-value-id='#{inventory_item.id}']")
      |> render_click()

      # Submit the edit form
      html = view
             |> form("form[phx-submit='save-mapping']", %{
               "item_id" => inventory_item.id,
               "platform_sku" => "UPDATED-SKU",
               "quantity" => "999"
             })
             |> render_submit()

      assert html =~ "Mapping updated successfully"
      assert html =~ "UPDATED-SKU"
      assert html =~ "999"
      refute html =~ "OLD-SKU"
    end

    test "deletes a channel mapping", %{conn: conn, product: product, channel: channel} do
      inventory_item = inventory_item_fixture(%{
        product_id: product.id,
        channel_id: channel.id,
        platform_sku: "DELETE-ME",
        quantity: 5
      })

      {:ok, view, _html} = live(conn, ~p"/products/#{product.id}")

      # Verify mapping exists
      assert render(view) =~ "DELETE-ME"

      # Delete the mapping
      html = view
             |> element("button[phx-click='delete-mapping'][phx-value-id='#{inventory_item.id}']")
             |> render_click()

      assert html =~ "Channel mapping removed"
      refute html =~ "DELETE-ME"
    end

    test "shows only unmapped channels in add modal", %{conn: conn, product: product, channel: channel} do
      # Create a second channel
      channel2 = channel_fixture(%{name: "Amazon Store", platform: :amazon})

      # Map the first channel to the product
      inventory_item_fixture(%{
        product_id: product.id,
        channel_id: channel.id,
        platform_sku: "MAPPED-SKU",
        quantity: 10
      })

      {:ok, view, _html} = live(conn, ~p"/products/#{product.id}")

      # Open modal
      html = view
             |> element("button", "Add Channel Mapping")
             |> render_click()

      # Should show unmapped channel, not the mapped one
      assert html =~ channel2.name
      refute html =~ ">#{channel.name}</option>"
    end

    test "navigates back to products list", %{conn: conn, product: product} do
      {:ok, view, _html} = live(conn, ~p"/products/#{product.id}")

      assert view
             |> element("a", "Back to Products")
             |> has_element?()
    end
  end
end
