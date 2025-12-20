defmodule InventorySync.Encrypted.Binary do
  @moduledoc """
  Encrypted binary field type using InventorySync.Vault for encryption.
  """

  use Cloak.Ecto.Binary, vault: InventorySync.Vault
end
