defmodule InventorySync.Integrations.ShopifyAdapterTest do
  use ExUnit.Case, async: true
  alias InventorySync.Integrations.ShopifyAdapter

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "update_inventory/3 makes correct API call to Shopify", %{bypass: bypass} do
    # 1. Setup Data
    port = bypass.port
    # We use http://localhost:port as the shop_url to match Bypass
    shop_url = "http://localhost:#{port}"

    credentials = %{
      "shop_url" => shop_url,
      "access_token" => "secret-token",
      "location_id" => "loc_123"
    }

    item = %{
      platform_sku: "SKU-123",
      external_id: "item_456"
    }

    quantity = 50

    # 2. Setup Mock Expectation
    Bypass.expect_once(bypass, "POST", "/admin/api/2024-01/inventory_levels/set.json", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      decoded_body = Jason.decode!(body)

      # Verify Request Body
      assert decoded_body["location_id"] == "loc_123"
      assert decoded_body["inventory_item_id"] == "item_456"
      assert decoded_body["available"] == 50

      # Verify Headers
      assert List.keyfind(conn.req_headers, "x-shopify-access-token", 0) ==
               {"x-shopify-access-token", "secret-token"}

      Plug.Conn.resp(conn, 200, Jason.encode!(%{inventory_level: %{available: 50}}))
    end)

    # 3. Call Adapter
    assert {:ok, _response} = ShopifyAdapter.update_inventory(credentials, item, quantity)
  end

  test "fetch_inventory/2 makes correct API call to Shopify", %{bypass: bypass} do
    # 1. Setup Data
    port = bypass.port
    shop_url = "http://localhost:#{port}"

    credentials = %{
      "shop_url" => shop_url,
      "access_token" => "secret-token",
      "location_id" => "loc_123"
    }

    item = %{
      platform_sku: "SKU-123",
      external_id: "item_456"
    }

    # 2. Setup Mock Expectation
    Bypass.expect_once(bypass, "GET", "/admin/api/2024-01/inventory_levels.json", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)

      # Verify Query Params
      assert conn.query_params["location_ids"] == "loc_123"
      assert conn.query_params["inventory_item_ids"] == "item_456"

      # Verify Headers
      assert List.keyfind(conn.req_headers, "x-shopify-access-token", 0) ==
               {"x-shopify-access-token", "secret-token"}

      response_body = %{
        inventory_levels: [
          %{
            location_id: 123,
            inventory_item_id: 456,
            available: 42
          }
        ]
      }

      Plug.Conn.resp(conn, 200, Jason.encode!(response_body))
    end)

    # 3. Call Adapter
    assert {:ok, 42} = ShopifyAdapter.fetch_inventory(credentials, item)
  end
end
