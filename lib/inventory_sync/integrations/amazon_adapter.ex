defmodule InventorySync.Integrations.AmazonAdapter do
  @behaviour InventorySync.Integrations.InventoryAdapter
  require Logger

  def update_inventory(_credentials, item, quantity) do
    Logger.info("AmazonAdapter: Updating #{item.platform_sku} to #{quantity} (STUB)")
    {:ok, %{status: "updated", platform: :amazon}}
  end

  def fetch_inventory(_credentials, item) do
    Logger.info("AmazonAdapter: Fetching #{item.platform_sku} (STUB)")
    {:ok, 0}
  end
end
