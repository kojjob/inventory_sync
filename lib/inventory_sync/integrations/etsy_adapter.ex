defmodule InventorySync.Integrations.EtsyAdapter do
  @behaviour InventorySync.Integrations.InventoryAdapter
  require Logger

  def update_inventory(_credentials, item, quantity) do
    Logger.info("EtsyAdapter: Updating #{item.platform_sku} to #{quantity} (STUB)")
    {:ok, %{status: "updated", platform: :etsy}}
  end

  def fetch_inventory(_credentials, item) do
    Logger.info("EtsyAdapter: Fetching #{item.platform_sku} (STUB)")
    {:ok, 0}
  end
end
