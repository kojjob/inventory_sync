defmodule InventorySyncWeb.WebhookController do
  use InventorySyncWeb, :controller

  require Logger

  alias InventorySync.Workers.WebhookProcessor

  def shopify(conn, %{"product_id" => product_id, "quantity" => quantity}) do
    # Enqueue job for async processing
    %{product_id: product_id, quantity: quantity}
    |> WebhookProcessor.new()
    |> Oban.insert()

    Logger.info("Shopify webhook enqueued for processing: product_id=#{product_id}")

    # Return 200 OK immediately
    json(conn, %{status: "accepted"})
  end

  def shopify(conn, _params) do
    Logger.warning("Received Shopify webhook with invalid parameters")
    send_resp(conn, 422, "invalid")
  end
end
