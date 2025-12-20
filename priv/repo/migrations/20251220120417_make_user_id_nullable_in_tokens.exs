defmodule InventorySync.Repo.Migrations.MakeUserIdNullableInTokens do
  use Ecto.Migration

  def change do
    alter table(:users_tokens) do
      modify :user_id, :bigint, null: true
    end
  end
end
