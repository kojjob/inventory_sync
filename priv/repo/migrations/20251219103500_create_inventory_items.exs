defmodule InventorySync.Repo.Migrations.CreateInventoryItems do
  use Ecto.Migration

  def change do
    create table(:inventory_items) do
      add :external_id, :string
      add :platform_sku, :string
      add :quantity, :integer
      add :channel_id, references(:channels, on_delete: :delete_all)
      add :product_id, references(:products, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:inventory_items, [:channel_id])
    create index(:inventory_items, [:product_id])
    create unique_index(:inventory_items, [:channel_id, :product_id])
    create unique_index(:inventory_items, [:channel_id, :external_id])
  end
end
