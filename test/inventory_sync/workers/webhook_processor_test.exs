defmodule InventorySync.Workers.WebhookProcessorTest do
  use InventorySync.DataCase, async: true
  use Oban.Testing, repo: InventorySync.Repo

  alias InventorySync.Workers.{WebhookProcessor, SyncManager}
  alias InventorySync.Inventory
  import InventorySync.InventoryFixtures

  setup do
    # Ensure MockAdapter is used for tests
    Application.put_env(:inventory_sync, :use_mock_adapter, true)

    on_exit(fn ->
      Application.delete_env(:inventory_sync, :use_mock_adapter)
    end)

    :ok
  end

  describe "perform/1" do
    test "successfully processes valid webhook" do
      # Setup channel and product
      channel = channel_fixture(platform: :shopify)
      {:ok, _pid} = SyncManager.start_channel(channel)

      product = product_fixture(total_quantity: 10)
      _item = inventory_item_fixture(channel_id: channel.id, product_id: product.id, quantity: 10)

      # Perform the job
      assert :ok = perform_job(WebhookProcessor, %{product_id: product.id, quantity: 5})

      # Verify product was updated
      updated = Inventory.get_product!(product.id)
      assert updated.total_quantity == 5
    end

    test "returns error for non-existent product" do
      # Attempt to process webhook for product that doesn't exist
      assert {:error, _} = perform_job(WebhookProcessor, %{product_id: 99999, quantity: 5})
    end

    test "returns error for invalid parameters" do
      # Missing required parameters
      assert {:error, :invalid_parameters} = perform_job(WebhookProcessor, %{invalid: "data"})
    end

    test "enqueues job correctly" do
      product = product_fixture()

      # Enqueue the job - in :inline mode, this executes immediately
      assert {:ok, %Oban.Job{state: "completed"}} =
               %{product_id: product.id, quantity: 15}
               |> WebhookProcessor.new()
               |> Oban.insert()

      # Verify product was updated (since job executed immediately in :inline mode)
      updated = Inventory.get_product!(product.id)
      assert updated.total_quantity == 15
    end

    test "respects max_attempts configuration" do
      # Verify the worker is configured for 5 max attempts
      assert WebhookProcessor.__opts__()[:max_attempts] == 5
    end

    test "uses webhooks queue" do
      # Verify the worker uses the correct queue
      assert WebhookProcessor.__opts__()[:queue] == :webhooks
    end
  end
end
