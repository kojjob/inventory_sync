defmodule InventorySync.Repo.Migrations.CreateChannels do
  use Ecto.Migration

  def change do
    create table(:channels) do
      add :name, :string
      add :platform, :string
      add :credentials, :map
      add :active, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
