defmodule InventorySync.Workers.WebhookProcessor do
  @moduledoc """
  Oban worker for processing Shopify webhooks asynchronously.

  This worker ensures webhooks are processed reliably without blocking
  the HTTP request, allowing the webhook endpoint to return 200 OK quickly.
  """
  use Oban.Worker,
    queue: :webhooks,
    max_attempts: 5,
    priority: 0

  require Logger

  alias InventorySync.Inventory

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"product_id" => product_id, "quantity" => quantity}}) do
    Logger.info("Processing Shopify webhook: product_id=#{product_id}, quantity=#{quantity}")

    try do
      case Inventory.update_product_quantity(product_id, quantity) do
        {:ok, _product} ->
          Logger.info("Successfully processed webhook for product #{product_id}")
          :ok

        {:error, reason} ->
          Logger.error("Failed to process webhook for product #{product_id}: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      Ecto.NoResultsError ->
        Logger.error("Product #{product_id} not found")
        {:error, :product_not_found}
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    Logger.warning("Received webhook with invalid or missing parameters: #{inspect(args)}")
    {:error, :invalid_parameters}
  end
end
