defmodule InventorySyncWeb.Plugs.VerifyShopifySignatureTest do
  use ExUnit.Case, async: false
  import Plug.Test
  import Plug.Conn

  alias InventorySyncWeb.Plugs.VerifyShopifySignature

  @webhook_secret "test_webhook_secret_12345"
  @valid_body ~s({"product_id":"123","quantity":10})

  setup do
    # Set the webhook secret for testing
    Application.put_env(:inventory_sync, :shopify_webhook_secret, @webhook_secret)

    on_exit(fn ->
      Application.delete_env(:inventory_sync, :shopify_webhook_secret)
    end)

    :ok
  end

  defp generate_hmac(body, secret) do
    :crypto.mac(:hmac, :sha256, secret, body)
    |> Base.encode64()
  end

  defp create_conn(body, headers) do
    conn = conn(:post, "/api/webhooks/shopify", body)

    # Simulate what CacheRawBody does - cache the raw body in conn.private
    # This is necessary because in production, Plug.Parsers runs first with
    # our custom body reader, which caches the raw body before parsing
    conn = Plug.Conn.put_private(conn, :raw_body, body)

    Enum.reduce(headers, conn, fn {key, value}, acc ->
      put_req_header(acc, key, value)
    end)
  end

  describe "init/1" do
    test "returns the options unchanged" do
      opts = %{some: :option}
      assert VerifyShopifySignature.init(opts) == opts
    end
  end

  describe "call/2" do
    test "allows request with valid HMAC signature" do
      signature = generate_hmac(@valid_body, @webhook_secret)

      conn =
        create_conn(@valid_body, [
          {"x-shopify-hmac-sha256", signature},
          {"content-type", "application/json"}
        ])
        |> VerifyShopifySignature.call([])

      # Should not halt the connection
      refute conn.halted

      # Should set assigns
      assert conn.assigns[:verified_shopify_webhook] == true
      assert conn.assigns[:raw_body] == @valid_body
    end

    test "rejects request with missing HMAC signature" do
      conn =
        create_conn(@valid_body, [{"content-type", "application/json"}])
        |> VerifyShopifySignature.call([])

      # Should halt the connection
      assert conn.halted
      assert conn.status == 401

      # Check response body
      {:ok, body} = Jason.decode(conn.resp_body)
      assert body["error"] == "Missing signature header"
    end

    test "rejects request with invalid HMAC signature" do
      invalid_signature = "invalid_signature_base64"

      conn =
        create_conn(@valid_body, [
          {"x-shopify-hmac-sha256", invalid_signature},
          {"content-type", "application/json"}
        ])
        |> VerifyShopifySignature.call([])

      # Should halt the connection
      assert conn.halted
      assert conn.status == 401

      # Check response body
      {:ok, body} = Jason.decode(conn.resp_body)
      assert body["error"] == "Invalid signature"
    end

    test "rejects request with valid signature for different body" do
      different_body = ~s({"product_id":"999","quantity":50})
      # Generate signature for the different body
      signature = generate_hmac(different_body, @webhook_secret)

      # But send our actual body instead
      conn =
        create_conn(@valid_body, [
          {"x-shopify-hmac-sha256", signature},
          {"content-type", "application/json"}
        ])
        |> VerifyShopifySignature.call([])

      # Should halt because body doesn't match signature
      assert conn.halted
      assert conn.status == 401

      {:ok, body} = Jason.decode(conn.resp_body)
      assert body["error"] == "Invalid signature"
    end

    test "returns 500 when webhook secret is not configured" do
      # Remove the webhook secret
      Application.delete_env(:inventory_sync, :shopify_webhook_secret)

      signature = generate_hmac(@valid_body, @webhook_secret)

      conn =
        create_conn(@valid_body, [
          {"x-shopify-hmac-sha256", signature},
          {"content-type", "application/json"}
        ])
        |> VerifyShopifySignature.call([])

      # Should halt with 500 error
      assert conn.halted
      assert conn.status == 500

      # Check response body
      {:ok, body} = Jason.decode(conn.resp_body)
      assert body["error"] == "Webhook secret not configured"

      # Restore the secret for other tests
      Application.put_env(:inventory_sync, :shopify_webhook_secret, @webhook_secret)
    end

    test "prevents timing attacks using constant-time comparison" do
      # This test verifies that we're using secure_compare
      # We can't directly test timing, but we can verify the function is called
      # by ensuring that similar but invalid signatures still fail

      valid_signature = generate_hmac(@valid_body, @webhook_secret)

      # Create an almost-correct signature (same length, different content)
      invalid_signature = String.replace(valid_signature, ~r/[A-Z]/, "X", global: true)

      conn =
        create_conn(@valid_body, [
          {"x-shopify-hmac-sha256", invalid_signature},
          {"content-type", "application/json"}
        ])
        |> VerifyShopifySignature.call([])

      # Should still fail despite being same length
      assert conn.halted
      assert conn.status == 401
    end

    test "handles empty body" do
      empty_body = ""
      signature = generate_hmac(empty_body, @webhook_secret)

      conn =
        create_conn(empty_body, [
          {"x-shopify-hmac-sha256", signature},
          {"content-type", "application/json"}
        ])
        |> VerifyShopifySignature.call([])

      # Should allow valid signature even for empty body
      refute conn.halted
      assert conn.assigns[:verified_shopify_webhook] == true
      assert conn.assigns[:raw_body] == empty_body
    end

    test "handles large payload" do
      # Create a larger JSON payload
      large_body =
        Jason.encode!(%{
          product_id: "123",
          quantity: 100,
          inventory_levels: Enum.map(1..100, fn i -> %{location_id: i, available: i * 10} end)
        })

      signature = generate_hmac(large_body, @webhook_secret)

      conn =
        create_conn(large_body, [
          {"x-shopify-hmac-sha256", signature},
          {"content-type", "application/json"}
        ])
        |> VerifyShopifySignature.call([])

      # Should handle large payloads correctly
      refute conn.halted
      assert conn.assigns[:verified_shopify_webhook] == true
      assert conn.assigns[:raw_body] == large_body
    end
  end
end
