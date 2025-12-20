defmodule InventorySync.Repo.Migrations.AddUniqueIndexToTeamMembersEmail do
  use Ecto.Migration

  def change do
    create unique_index(:team_members, [:email])
  end
end
