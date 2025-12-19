defmodule InventorySyncWeb.WebhookControllerTest do
  use InventorySyncWeb.ConnCase, async: true

  import InventorySync.InventoryFixtures
  alias InventorySync.Workers.SyncManager
  alias InventorySync.Inventory

  test "POST /api/webhooks/shopify updates product and syncs channels", %{conn: conn} do
    channel = channel_fixture(platform: :shopify)
    {:ok, _pid} = SyncManager.start_channel(channel)

    product = product_fixture(total_quantity: 10)
    _item = inventory_item_fixture(channel_id: channel.id, product_id: product.id, quantity: 10)

    conn = post(conn, "/api/webhooks/shopify", %{product_id: product.id, quantity: 7})
    assert json_response(conn, 200) == %{"status" => "ok"}

    updated = Inventory.get_product!(product.id)
    assert updated.total_quantity == 7
  end
end

