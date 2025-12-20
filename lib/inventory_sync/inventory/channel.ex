defmodule InventorySync.Inventory.Channel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "channels" do
    field :name, :string
    field :platform, Ecto.Enum, values: [:shopify, :amazon, :etsy, :ebay]
    field :credentials, InventorySync.Encrypted.Binary
    field :active, :boolean, default: false

    has_many :inventory_items, InventorySync.Inventory.InventoryItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:name, :platform, :credentials, :active])
    |> validate_required([:name, :platform])
    |> validate_inclusion(:platform, [:shopify, :amazon, :etsy, :ebay])
  end
end
