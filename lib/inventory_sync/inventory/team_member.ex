defmodule InventorySync.Inventory.TeamMember do
  use Ecto.Schema
  import Ecto.Changeset

  schema "team_members" do
    field :name, :string
    field :email, :string
    field :title, :string
    field :role, :string
    field :status, :string
    field :invitation_sent_at, :utc_datetime
    field :invitation_accepted_at, :utc_datetime

    belongs_to :user, InventorySync.Accounts.User
    belongs_to :invited_by, InventorySync.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(team_member, attrs) do
    team_member
    |> cast(attrs, [:name, :email, :title, :role, :status])
    |> validate_required([:email, :role])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> unique_constraint(:email)
  end

  @doc """
  Changeset for creating an invitation. Only email and role are required.
  Name and title can be filled in by the invited user when they accept.
  """
  def invitation_changeset(team_member, attrs) do
    team_member
    |> cast(attrs, [:email, :role, :title, :invited_by_id])
    |> validate_required([:email, :role, :invited_by_id])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> unique_constraint(:email)
    |> put_change(:status, "Invited")
    |> put_change(:invitation_sent_at, DateTime.utc_now(:second))
  end

  @doc """
  Changeset for accepting an invitation and linking to a user account.
  """
  def accept_invitation_changeset(team_member, user_id, attrs \\ %{}) do
    team_member
    |> cast(attrs, [:name, :title])
    |> validate_invitation_not_accepted()
    |> put_change(:user_id, user_id)
    |> put_change(:invitation_accepted_at, DateTime.utc_now(:second))
    |> put_change(:status, "Active")
    |> validate_required([:user_id])
  end

  defp validate_invitation_not_accepted(changeset) do
    if get_field(changeset, :user_id) do
      add_error(changeset, :user_id, "has already been accepted")
    else
      changeset
    end
  end
end
