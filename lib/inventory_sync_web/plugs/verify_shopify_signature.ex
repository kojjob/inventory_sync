defmodule InventorySyncWeb.Plugs.VerifyShopifySignature do
  @moduledoc """
  Plug to verify Shopify webhook HMAC signatures.

  Shopify sends webhooks with an X-Shopify-Hmac-Sha256 header containing
  a base64-encoded HMAC-SHA256 hash of the request body.

  This plug:
  1. Reads the signature from the header
  2. Computes the expected HMAC using the webhook secret
  3. Compares them in constant time to prevent timing attacks
  4. Rejects the request if verification fails

  ## Configuration

  Add to config/runtime.exs:

      config :inventory_sync, :shopify_webhook_secret, System.get_env("SHOPIFY_WEBHOOK_SECRET")

  ## Usage

  In your controller:

      plug InventorySyncWeb.Plugs.VerifyShopifySignature when action in [:shopify]

  Or in your router pipeline:

      pipeline :shopify_webhooks do
        plug :accepts, ["json"]
        plug InventorySyncWeb.Plugs.VerifyShopifySignature
      end
  """

  import Plug.Conn
  require Logger

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    # Get the signature from the header
    signature_header = get_req_header(conn, "x-shopify-hmac-sha256") |> List.first()

    if signature_header do
      verify_signature(conn, signature_header)
    else
      Logger.warning("Shopify webhook request missing HMAC signature header")

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(401, Jason.encode!(%{error: "Missing signature header"}))
      |> halt()
    end
  end

  defp verify_signature(conn, signature_header) do
    # Get the raw body from the cache (set by CacheRawBody body reader)
    # This preserves the exact bytes that were signed by Shopify
    body = conn.private[:raw_body] || ""

    # Get the webhook secret from config
    secret = get_webhook_secret()

    if secret do
      # Compute the expected HMAC
      expected_hmac = :crypto.mac(:hmac, :sha256, secret, body)
      expected_signature = Base.encode64(expected_hmac)

      # Compare signatures in constant time to prevent timing attacks
      if Plug.Crypto.secure_compare(expected_signature, signature_header) do
        Logger.debug("Shopify webhook signature verified successfully")

        # Store verification flag in assigns
        conn
        |> assign(:raw_body, body)
        |> assign(:verified_shopify_webhook, true)
      else
        Logger.warning("Shopify webhook signature verification failed")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Invalid signature"}))
        |> halt()
      end
    else
      Logger.error("Shopify webhook secret not configured! Set SHOPIFY_WEBHOOK_SECRET environment variable.")

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(500, Jason.encode!(%{error: "Webhook secret not configured"}))
      |> halt()
    end
  end

  defp get_webhook_secret do
    Application.get_env(:inventory_sync, :shopify_webhook_secret)
  end
end
