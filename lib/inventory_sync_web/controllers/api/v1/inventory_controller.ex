defmodule InventorySyncWeb.Api.V1.InventoryController do
  @moduledoc """
  API controller for inventory management operations.

  Provides endpoints for:
  - Listing all inventory items with product and channel details
  - Updating product quantities by SKU (triggers sync to all channels)
  """

  use InventorySyncWeb, :controller

  alias InventorySync.Inventory

  action_fallback InventorySyncWeb.Api.V1.FallbackController

  # Require write scope for update action
  plug :require_write_scope when action in [:update]

  @doc """
  Lists all inventory items with their associated product and channel information.

  Returns a list of inventory records showing quantity allocations per channel.
  """
  def index(conn, _params) do
    inventory_items = Inventory.list_inventory_items() |> preload_associations()
    render(conn, :index, inventory_items: inventory_items)
  end

  @doc """
  Updates product quantity by SKU.

  This triggers inventory sync to all connected channels via PubSub.
  The quantity update is atomic - either all channels receive the update or none do.
  """
  def update(conn, %{"sku" => sku, "inventory" => inventory_params}) do
    case Inventory.get_product_by_sku(sku) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
        |> render(:not_found)

      product ->
        quantity = Map.get(inventory_params, "quantity", product.total_quantity)

        case Inventory.update_product_quantity(product.id, quantity) do
          {:ok, updated_product} ->
            # Preload inventory items for response
            updated_product =
              InventorySync.Repo.preload(updated_product, inventory_items: :channel)

            render(conn, :show, product: updated_product)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
            |> render(:changeset_errors, changeset: changeset)
        end
    end
  end

  # Handle update without inventory params - return bad request
  def update(conn, %{"sku" => _sku}) do
    conn
    |> put_status(:bad_request)
    |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
    |> render(:bad_request, message: "Missing inventory parameters")
  end

  # Private functions

  defp preload_associations(inventory_items) do
    InventorySync.Repo.preload(inventory_items, [:product, :channel])
  end

  defp require_write_scope(conn, _opts) do
    api_token = conn.assigns[:api_token]

    if api_token && InventorySync.Accounts.ApiToken.has_scope?(api_token, "write:inventory") do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
      |> render(:forbidden)
      |> halt()
    end
  end
end
