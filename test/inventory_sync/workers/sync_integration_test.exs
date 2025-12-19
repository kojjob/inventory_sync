defmodule InventorySync.Workers.SyncIntegrationTest do
  use InventorySync.DataCase
  import ExUnit.CaptureLog

  alias InventorySync.Workers.SyncManager
  alias InventorySync.Inventory
  import InventorySync.InventoryFixtures

  test "updating product quantity triggers channel sync" do
    # 1. Setup Data
    channel = channel_fixture(platform: :shopify)
    product = product_fixture(total_quantity: 50)
    inventory_item = inventory_item_fixture(channel_id: channel.id, product_id: product.id, quantity: 50)

    # 2. Start ChannelServer
    {:ok, _pid} = SyncManager.start_channel(channel)
    
    # 3. Update Product Quantity and capture logs
    new_quantity = 45
    
    log = capture_log(fn ->
      {:ok, updated_product} = Inventory.update_product_quantity(product.id, new_quantity)
      assert updated_product.total_quantity == new_quantity
      
      # Allow some time for the async PubSub -> GenServer -> Adapter flow
      Process.sleep(100)
    end)

    # 4. Verify logs indicate success
    assert log =~ "Received sync_inventory for #{channel.name}"
    # Since we use MockAdapter in tests, we verify the ChannelServer success log
    assert log =~ "Successfully synced SKU #{inventory_item.platform_sku} to #{channel.name}"
    
    # 5. Verify DB state
    updated_item = Inventory.get_inventory_item!(inventory_item.id)
    assert updated_item.quantity == new_quantity
  end
end
