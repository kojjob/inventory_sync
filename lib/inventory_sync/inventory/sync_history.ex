defmodule InventorySync.Inventory.SyncHistory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sync_history" do
    field :sku, :string
    field :channel_name, :string
    field :status, :string
    field :message, :string
    field :timestamp, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sync_history, attrs) do
    sync_history
    |> cast(attrs, [:sku, :channel_name, :status, :message, :timestamp])
    |> validate_required([:sku, :channel_name, :status, :message, :timestamp])
  end
end
