defmodule InventorySyncWeb.Api.V1.InventoryJSON do
  @moduledoc """
  JSON serializer for Inventory resources in the API.

  Provides inventory visibility across products and channels with
  standardized envelope format:
  - Inventory list: `{"data": [...]}`
  - Product inventory: `{"data": {...}}`
  """

  alias InventorySync.Inventory.{InventoryItem, Product}

  @doc """
  Renders a list of inventory items with product and channel details.
  """
  def index(%{inventory_items: inventory_items}) do
    %{data: for(item <- inventory_items, do: inventory_item_data(item))}
  end

  @doc """
  Renders a single product with its inventory across all channels.
  """
  def show(%{product: product}) do
    %{data: product_inventory_data(product)}
  end

  @doc """
  Serializes an inventory item to a JSON-compatible map.
  """
  def inventory_item_data(%InventoryItem{} = item) do
    %{
      id: item.id,
      sku: get_product_sku(item),
      platform_sku: item.platform_sku,
      quantity: item.quantity,
      product: product_summary(item.product),
      channel: channel_summary(item.channel),
      updated_at: item.updated_at
    }
  end

  @doc """
  Serializes a product with its inventory allocations across channels.
  """
  def product_inventory_data(%Product{} = product) do
    %{
      sku: product.sku,
      name: product.name,
      total_quantity: product.total_quantity,
      inventory: inventory_by_channel(product),
      updated_at: product.updated_at
    }
  end

  # Private helpers

  defp get_product_sku(%{product: %Product{sku: sku}}), do: sku
  defp get_product_sku(%{product: nil}), do: nil
  defp get_product_sku(_), do: nil

  defp product_summary(nil), do: nil

  defp product_summary(%Product{} = product) do
    %{
      id: product.id,
      sku: product.sku,
      name: product.name,
      total_quantity: product.total_quantity
    }
  end

  defp channel_summary(nil), do: nil

  defp channel_summary(channel) do
    %{
      id: channel.id,
      name: channel.name,
      platform: channel.platform,
      active: channel.active
    }
  end

  defp inventory_by_channel(%{inventory_items: items}) when is_list(items) do
    Enum.map(items, fn item ->
      %{
        channel_id: item.channel_id,
        channel_name: get_channel_name(item),
        platform: get_channel_platform(item),
        platform_sku: item.platform_sku,
        quantity: item.quantity,
        synced_at: item.updated_at
      }
    end)
  end

  defp inventory_by_channel(_), do: []

  defp get_channel_name(%{channel: %{name: name}}), do: name
  defp get_channel_name(_), do: nil

  defp get_channel_platform(%{channel: %{platform: platform}}), do: platform
  defp get_channel_platform(_), do: nil
end
