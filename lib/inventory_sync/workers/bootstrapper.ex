defmodule InventorySync.Workers.Bootstrapper do
  use GenServer
  alias InventorySync.Inventory
  alias InventorySync.Workers.SyncManager

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, :ok, {:continue, :start_channels}}
  end

  def handle_continue(:start_channels, state) do
    # Skip database queries in test environment to avoid ownership errors
    unless Application.get_env(:inventory_sync, :use_mock_adapter, false) do
      Inventory.list_channels()
      |> Enum.filter(& &1.active)
      |> Enum.each(&SyncManager.start_channel/1)
    end

    {:noreply, state}
  end
end
