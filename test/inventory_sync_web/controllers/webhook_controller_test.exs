defmodule InventorySyncWeb.WebhookControllerTest do
  use InventorySyncWeb.ConnCase, async: false

  import InventorySync.InventoryFixtures
  alias InventorySync.Workers.SyncManager
  alias InventorySync.Inventory

  @webhook_secret "test_webhook_secret_12345"

  setup do
    # Set the webhook secret for testing
    Application.put_env(:inventory_sync, :shopify_webhook_secret, @webhook_secret)

    on_exit(fn ->
      Application.delete_env(:inventory_sync, :shopify_webhook_secret)
    end)

    :ok
  end

  defp generate_hmac(body, secret) do
    :crypto.mac(:hmac, :sha256, secret, body)
    |> Base.encode64()
  end

  test "POST /api/webhooks/shopify enqueues job and processes async", %{conn: conn} do
    channel = channel_fixture(platform: :shopify)
    {:ok, _pid} = SyncManager.start_channel(channel)

    product = product_fixture(total_quantity: 10)
    _item = inventory_item_fixture(channel_id: channel.id, product_id: product.id, quantity: 10)

    # Create the request body
    body = Jason.encode!(%{product_id: product.id, quantity: 7})
    signature = generate_hmac(body, @webhook_secret)

    # Send the signed webhook request
    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-shopify-hmac-sha256", signature)
      |> post("/api/webhooks/shopify", body)

    # Controller should return "accepted" immediately (async processing)
    assert json_response(conn, 200) == %{"status" => "accepted"}

    # In :inline test mode, the job executes synchronously
    # Verify the product was updated
    updated = Inventory.get_product!(product.id)
    assert updated.total_quantity == 7
  end
end
