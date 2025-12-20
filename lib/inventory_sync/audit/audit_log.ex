defmodule InventorySync.Audit.AuditLog do
  @moduledoc """
  Schema for tracking user actions across the system.
  Records who did what, when, and what changed.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias InventorySync.Accounts.User

  schema "audit_logs" do
    field :action, :string
    field :resource_type, :string
    field :resource_id, :integer
    field :changes, :map, default: %{}
    field :metadata, :map, default: %{}

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:action, :resource_type, :resource_id, :changes, :metadata, :user_id])
    |> validate_required([:action, :resource_type, :resource_id, :user_id])
    |> validate_inclusion(:action, ~w(created updated deleted invited settings_changed))
    |> foreign_key_constraint(:user_id)
  end
end
