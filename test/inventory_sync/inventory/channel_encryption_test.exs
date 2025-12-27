defmodule InventorySync.Inventory.ChannelEncryptionTest do
  use InventorySync.DataCase, async: true

  alias InventorySync.Inventory

  describe "credential encryption" do
    test "encrypts and decrypts credentials correctly" do
      # Create credentials as map (Encrypted.Map handles JSON serialization internally)
      credentials = %{
        "api_key" => "test_secret_key_12345",
        "shop_url" => "test-shop.myshopify.com"
      }

      # Create a channel with encrypted credentials
      {:ok, channel} =
        Inventory.create_channel(%{
          name: "Test Encrypted Channel",
          platform: :shopify,
          credentials: credentials
        })

      assert channel.id
      assert channel.credentials == credentials

      # Fetch from database to verify encryption/decryption round-trip
      fetched_channel = Inventory.get_channel!(channel.id)

      assert fetched_channel.credentials == credentials

      # Verify we can access the credentials directly as a map
      assert fetched_channel.credentials["api_key"] == "test_secret_key_12345"
      assert fetched_channel.credentials["shop_url"] == "test-shop.myshopify.com"
    end

    test "handles nil credentials" do
      {:ok, channel} =
        Inventory.create_channel(%{
          name: "Channel Without Credentials",
          platform: :shopify,
          credentials: nil
        })

      assert channel.credentials == nil

      fetched_channel = Inventory.get_channel!(channel.id)
      assert fetched_channel.credentials == nil
    end

    test "credentials are actually encrypted in database" do
      credentials = %{"api_key" => "secret123"}

      {:ok, channel} =
        Inventory.create_channel(%{
          name: "Test Channel",
          platform: :shopify,
          credentials: credentials
        })

      # Query raw database to verify encryption
      result =
        Repo.query!(
          "SELECT credentials FROM channels WHERE id = $1",
          [channel.id]
        )

      [[encrypted_binary]] = result.rows

      # Verify it's binary data, not plain text
      assert is_binary(encrypted_binary)
      # Verify it doesn't contain the plaintext secret
      refute String.contains?(encrypted_binary, "secret123")
    end
  end
end
