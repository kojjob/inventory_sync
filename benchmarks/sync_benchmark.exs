# benchmarks/sync_benchmark.exs
# Run with: mix run benchmarks/sync_benchmark.exs

# Ensure we're using the mock adapter to avoid external calls during benchmark
Application.put_env(:inventory_sync, :use_mock_adapter, true)

alias InventorySync.Inventory
alias InventorySync.Workers.SyncManager

# 1. Setup Data
IO.puts("Setting up benchmark data...")

# Create a product
{:ok, product} = Inventory.create_product(%{
  sku: "BENCH-SKU-001",
  name: "Benchmark Product",
  total_quantity: 1000,
  price: "10.00"
})

# Create multiple channels to simulate fan-out
channels = Enum.map(1..5, fn i ->
  {:ok, channel} = Inventory.create_channel(%{
    name: "Channel #{i}",
    platform: :shopify, # Will use MockAdapter due to config above
    active: true,
    credentials: %{"shop_url" => "example.com", "access_token" => "123"}
  })
  
  # Link inventory item
  {:ok, _item} = Inventory.create_inventory_item(%{
    product_id: product.id,
    channel_id: channel.id,
    platform_sku: "BENCH-#{i}",
    external_id: "EXT-#{i}",
    quantity: 1000
  })
  
  # Start ChannelServer
  SyncManager.start_channel(channel)
  
  channel
end)

IO.puts("Created 1 Product linked to #{length(channels)} Channels.")

# 2. Define Benchmark
Benchee.run(
  %{
    "update_product_quantity (Fan-out 5)" => fn ->
      # We update to a random quantity to ensure DB writes happen (if checking for changes)
      # But our logic blindly updates, so it's fine.
      new_qty = :rand.uniform(1000)
      {:ok, _} = Inventory.update_product_quantity(product.id, new_qty)
    end
  },
  time: 10,
  memory_time: 2,
  warmup: 2
)
