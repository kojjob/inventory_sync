defmodule InventorySync.Integrations.MockAdapter do
  @behaviour InventorySync.Integrations.InventoryAdapter

  def update_inventory(_credentials, _item, _quantity) do
    {:ok, %{status: "updated"}}
  end

  def fetch_inventory(_credentials, _item) do
    {:ok, 100}
  end
end
