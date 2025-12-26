defmodule InventorySync.Repo.Migrations.CreateApiTokens do
  use Ecto.Migration

  def change do
    create table(:api_tokens) do
      add :token_hash, :binary, null: false
      add :name, :string, null: false
      add :scopes, {:array, :string}, null: false, default: []
      add :last_used_at, :utc_datetime
      add :expires_at, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    # Index on token_hash for fast lookups during verification
    create unique_index(:api_tokens, [:token_hash])

    # Index on user_id for listing user's tokens
    create index(:api_tokens, [:user_id])
  end
end
