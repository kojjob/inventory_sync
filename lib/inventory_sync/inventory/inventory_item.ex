defmodule InventorySync.Inventory.InventoryItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "inventory_items" do
    field :external_id, :string
    field :platform_sku, :string
    field :quantity, :integer
    belongs_to :channel, InventorySync.Inventory.Channel
    belongs_to :product, InventorySync.Inventory.Product

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(inventory_item, attrs) do
    inventory_item
    |> cast(attrs, [:external_id, :platform_sku, :quantity, :channel_id, :product_id])
    |> validate_required([:external_id, :platform_sku, :quantity, :channel_id, :product_id])
    |> unique_constraint([:channel_id, :product_id])
    |> unique_constraint([:channel_id, :external_id])
  end
end
