defmodule InventorySync.Inventory.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "team_members" do
    field :name, :string
    field :email, :string
    field :title, :string
    field :role, :string
    field :status, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :title, :role, :status])
    |> validate_required([:name, :email, :title, :role, :status])
  end
end
