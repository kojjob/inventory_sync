defmodule InventorySync.Repo.Migrations.CreateInventoryEvents do
  use Ecto.Migration

  def change do
    create table(:inventory_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_type, :string, null: false
      add :aggregate_id, :string, null: false
      add :aggregate_type, :string, null: false
      add :payload, :map, null: false, default: %{}
      add :metadata, :map, null: false, default: %{}
      add :version, :integer, null: false
      add :occurred_at, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec)
    end

    # Index for querying events by aggregate
    create index(:inventory_events, [:aggregate_type, :aggregate_id])

    # Index for replaying events in order
    create index(:inventory_events, [:aggregate_id, :version])

    # Index for querying by event type
    create index(:inventory_events, [:event_type])

    # Index for time-based queries (audit trail, debugging)
    create index(:inventory_events, [:occurred_at])

    # Unique constraint to prevent duplicate versions for an aggregate
    create unique_index(:inventory_events, [:aggregate_id, :version],
             name: :inventory_events_aggregate_version_unique
           )
  end
end
