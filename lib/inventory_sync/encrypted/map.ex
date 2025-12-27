defmodule InventorySync.Encrypted.Map do
  @moduledoc """
  Encrypted map field type using InventorySync.Vault for encryption.

  This type serializes maps to JSON before encryption and deserializes
  back to maps after decryption. Useful for storing structured data
  like API credentials.
  """

  use Cloak.Ecto.Type, vault: InventorySync.Vault

  @doc false
  def cast(nil), do: {:ok, nil}

  def cast(value) when is_map(value) do
    {:ok, value}
  end

  def cast(value) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, decoded} when is_map(decoded) -> {:ok, decoded}
      _ -> :error
    end
  end

  def cast(_), do: :error

  @doc false
  def before_encrypt(nil), do: nil

  def before_encrypt(value) when is_map(value) do
    Jason.encode!(value)
  end

  def before_encrypt(value), do: to_string(value)

  @doc false
  def after_decrypt(nil), do: nil

  def after_decrypt(value) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, decoded} -> decoded
      _ -> value
    end
  end

  def after_decrypt(value), do: value
end
