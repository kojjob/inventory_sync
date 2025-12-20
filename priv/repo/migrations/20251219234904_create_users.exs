defmodule InventorySync.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string
      add :title, :string
      add :role, :string
      add :status, :string

      timestamps(type: :utc_datetime)
    end
  end
end
