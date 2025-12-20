defmodule InventorySync.InventoryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `InventorySync.Inventory` context.
  """

  @doc """
  Generate a channel.
  """
  def channel_fixture(attrs \\ %{}) do
    {:ok, channel} =
      attrs
      |> Enum.into(%{
        active: true,
        credentials: Jason.encode!(%{}),
        name: "some name",
        platform: :shopify
      })
      |> InventorySync.Inventory.create_channel()

    channel
  end

  @doc """
  Generate a unique product sku.
  """
  def unique_product_sku, do: "some sku#{System.unique_integer([:positive])}"

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        name: "some name",
        sku: unique_product_sku(),
        total_quantity: 42
      })
      |> InventorySync.Inventory.create_product()

    product
  end

  @doc """
  Generate a inventory_item.
  """
  def inventory_item_fixture(attrs \\ %{}) do
    channel = attrs[:channel_id] && InventorySync.Inventory.get_channel!(attrs[:channel_id]) || channel_fixture()
    product = attrs[:product_id] && InventorySync.Inventory.get_product!(attrs[:product_id]) || product_fixture()

    {:ok, inventory_item} =
      attrs
      |> Enum.into(%{
        external_id: "some external_id",
        platform_sku: "some platform_sku",
        quantity: 42,
        channel_id: channel.id,
        product_id: product.id
      })
      |> InventorySync.Inventory.create_inventory_item()

    inventory_item
  end

  @doc """
  Generate a team_member.
  """
  def team_member_fixture(attrs \\ %{}) do
    {:ok, team_member} =
      attrs
      |> Enum.into(%{
        name: "Team Member #{System.unique_integer([:positive])}",
        email: "member#{System.unique_integer([:positive])}@example.com",
        role: "viewer"
      })
      |> InventorySync.Inventory.create_team_member()

    team_member
  end
end
