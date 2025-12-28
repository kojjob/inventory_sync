defmodule InventorySyncWeb.Api.V1.ProductJSON do
  @moduledoc """
  JSON serializer for Product resources in the API.

  Wraps product data in a standard envelope format:
  - Single product: `{"data": {...}}`
  - List of products: `{"data": [...]}`
  """

  alias InventorySync.Inventory.Product

  @doc """
  Renders a list of products.
  """
  def index(%{products: products}) do
    %{data: for(product <- products, do: data(product))}
  end

  @doc """
  Renders a single product.
  """
  def show(%{product: product}) do
    %{data: data(product)}
  end

  @doc """
  Serializes a product to a JSON-compatible map.
  """
  def data(%Product{} = product) do
    %{
      id: product.id,
      sku: product.sku,
      name: product.name,
      total_quantity: product.total_quantity,
      inserted_at: product.inserted_at,
      updated_at: product.updated_at
    }
  end
end
