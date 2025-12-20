defmodule InventorySync.Repo.Migrations.AddInvitationFieldsToTeamMembers do
  use Ecto.Migration

  def change do
    alter table(:team_members) do
      add :user_id, references(:users, on_delete: :nilify_all)
      add :invitation_sent_at, :utc_datetime
      add :invitation_accepted_at, :utc_datetime
      add :invited_by_id, references(:users, on_delete: :nilify_all)
    end

    create index(:team_members, [:user_id])
    create index(:team_members, [:invited_by_id])
  end
end
