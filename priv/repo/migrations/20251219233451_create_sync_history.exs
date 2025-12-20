defmodule InventorySync.Repo.Migrations.CreateSyncHistory do
  use Ecto.Migration

  def change do
    create table(:sync_history) do
      add :sku, :string
      add :channel_name, :string
      add :status, :string
      add :message, :text
      add :timestamp, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
