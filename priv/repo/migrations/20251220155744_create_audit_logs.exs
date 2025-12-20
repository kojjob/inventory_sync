defmodule InventorySync.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :action, :string, null: false
      add :resource_type, :string, null: false
      add :resource_id, :integer, null: false
      add :changes, :map, default: %{}
      add :metadata, :map, default: %{}
      add :user_id, references(:users, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:audit_logs, [:user_id])
    create index(:audit_logs, [:resource_type, :resource_id])
    create index(:audit_logs, [:action])
    create index(:audit_logs, [:inserted_at])
  end
end
