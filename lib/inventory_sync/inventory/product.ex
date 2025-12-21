defmodule InventorySync.Inventory.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :sku, :string
    field :name, :string
    field :total_quantity, :integer

    has_many :inventory_items, InventorySync.Inventory.InventoryItem
    has_many :channels, through: [:inventory_items, :channel]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:sku, :name, :total_quantity])
    |> validate_required([:sku, :name, :total_quantity])
    |> unique_constraint(:sku)
  end
end
