defmodule InventorySync.Integrations.ShopifyAdapter do
  @behaviour InventorySync.Integrations.InventoryAdapter
  require Logger

  @doc """
  Updates inventory for a specific item on Shopify.
  Requires `credentials` to contain `shop_url` (e.g., "my-shop.myshopify.com"), `access_token`, and optionally `location_id`.
  If `location_id` is missing, it should be fetched or stored in the inventory item.
  For this MVP, we assume `location_id` is passed in credentials or we default to the first location found (future improvement).
  """
  def update_inventory(credentials, item, quantity) do
    Logger.info("ShopifyAdapter: Updating #{item.platform_sku} to #{quantity}")

    shop_url = credentials["shop_url"]
    access_token = credentials["access_token"]
    location_id = credentials["location_id"]
    inventory_item_id = item.external_id

    if is_nil(shop_url) or is_nil(access_token) or is_nil(location_id) do
      Logger.error("ShopifyAdapter: Missing credentials (shop_url, access_token, or location_id)")
      {:error, :missing_credentials}
    else
      base_url =
        if String.starts_with?(shop_url, "http"), do: shop_url, else: "https://#{shop_url}"

      url = "#{base_url}/admin/api/2024-01/inventory_levels/set.json"

      body = %{
        "location_id" => location_id,
        "inventory_item_id" => inventory_item_id,
        "available" => quantity
      }

      Req.post(url,
        json: body,
        headers: [
          {"X-Shopify-Access-Token", access_token},
          {"Content-Type", "application/json"}
        ]
      )
      |> handle_response()
    end
  end

  def fetch_inventory(credentials, item) do
    Logger.info("ShopifyAdapter: Fetching #{item.platform_sku}")

    shop_url = credentials["shop_url"]
    access_token = credentials["access_token"]
    location_id = credentials["location_id"]
    inventory_item_id = item.external_id

    if is_nil(shop_url) or is_nil(access_token) or is_nil(location_id) do
      Logger.error("ShopifyAdapter: Missing credentials")
      {:error, :missing_credentials}
    else
      base_url =
        if String.starts_with?(shop_url, "http"), do: shop_url, else: "https://#{shop_url}"

      url = "#{base_url}/admin/api/2024-01/inventory_levels.json"

      Req.get(url,
        params: [
          inventory_item_ids: inventory_item_id,
          location_ids: location_id
        ],
        headers: [
          {"X-Shopify-Access-Token", access_token},
          {"Content-Type", "application/json"}
        ]
      )
      |> handle_fetch_response()
    end
  end

  defp handle_response({:ok, %Req.Response{status: 200, body: body}}) do
    {:ok, body}
  end

  defp handle_response({:ok, %Req.Response{status: 201, body: body}}) do
    {:ok, body}
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}}) do
    Logger.error("ShopifyAdapter: API Error #{status}: #{inspect(body)}")
    {:error, {:http_error, status, body}}
  end

  defp handle_response({:error, reason}) do
    Logger.error("ShopifyAdapter: Network Error: #{inspect(reason)}")
    {:error, reason}
  end

  defp handle_fetch_response(
         {:ok, %Req.Response{status: 200, body: %{"inventory_levels" => [level | _]}}}
       ) do
    {:ok, level["available"]}
  end

  defp handle_fetch_response({:ok, %Req.Response{status: 200, body: %{"inventory_levels" => []}}}) do
    Logger.warning("ShopifyAdapter: Item not found in location")
    {:error, :not_found}
  end

  defp handle_fetch_response(response), do: handle_response(response)
end
