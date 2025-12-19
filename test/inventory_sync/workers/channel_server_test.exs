defmodule InventorySync.Workers.ChannelServerTest do
  use InventorySync.DataCase

  alias InventorySync.Workers.{ChannelServer, SyncManager}
  alias InventorySync.Inventory

  import InventorySync.InventoryFixtures

  test "starts a channel server and updates inventory via mock adapter" do
    # Use a platform that falls back to MockAdapter (via config)
    channel = channel_fixture(platform: :shopify)

    # Start the server via SyncManager
    {:ok, pid} = SyncManager.start_channel(channel)
    assert Process.alive?(pid)

    # Create a product and inventory item
    product = product_fixture()
    inventory_item = inventory_item_fixture(channel_id: channel.id, product_id: product.id)

    # Call update_inventory
    assert {:ok, %{status: "updated"}} = ChannelServer.update_inventory(channel.id, inventory_item, 10)
  end
end
