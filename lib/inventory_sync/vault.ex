defmodule InventorySync.Vault do
  @moduledoc """
  Vault for encrypting sensitive data like API credentials.

  Uses Cloak.Ecto for transparent field-level encryption.
  The encryption key is stored in the CLOAK_KEY environment variable.
  """

  use Cloak.Vault, otp_app: :inventory_sync

  def init(config) do
    config =
      Keyword.put(config, :ciphers,
        default: {
          Cloak.Ciphers.AES.GCM,
          tag: "AES.GCM.V1", key: decode_env!("CLOAK_KEY")
        }
      )

    {:ok, config}
  end

  defp decode_env!(var) do
    var
    |> System.get_env()
    |> case do
      nil -> raise "Environment variable #{var} is not set!"
      key -> Base.decode64!(key)
    end
  end
end
