defmodule InventorySync.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :sku, :string
      add :name, :string
      add :total_quantity, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:products, [:sku])
  end
end
