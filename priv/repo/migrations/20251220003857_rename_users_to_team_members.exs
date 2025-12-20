defmodule InventorySync.Repo.Migrations.RenameUsersToTeamMembers do
  use Ecto.Migration

  def change do
    rename table(:users), to: table(:team_members)
  end
end
