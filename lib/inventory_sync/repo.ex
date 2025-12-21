defmodule InventorySync.Repo do
  use Ecto.Repo,
    otp_app: :inventory_sync,
    adapter: Ecto.Adapters.Postgres
end
