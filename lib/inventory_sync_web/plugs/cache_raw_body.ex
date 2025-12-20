defmodule InventorySyncWeb.Plugs.CacheRawBody do
  @moduledoc """
  A custom body reader that caches the raw request body.

  This is required for webhook signature verification where we need access
  to the exact raw bytes that were signed by the webhook sender.

  ## Usage

  Configure in your endpoint's Plug.Parsers:

      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        body_reader: {InventorySyncWeb.Plugs.CacheRawBody, :read_body, []},
        json_decoder: Phoenix.json_library()

  Then access the cached body in your plug:

      raw_body = conn.private[:raw_body] || ""
  """

  @doc """
  Reads the request body and caches it in conn.private[:raw_body].

  This function has the same signature as Plug.Conn.read_body/2.
  """
  def read_body(%Plug.Conn{} = conn, opts \\ []) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        # Cache the raw body in conn.private
        conn = Plug.Conn.put_private(conn, :raw_body, body)
        {:ok, body, conn}

      {:more, body, conn} ->
        # For chunked reads, accumulate the body
        existing = conn.private[:raw_body] || ""
        conn = Plug.Conn.put_private(conn, :raw_body, existing <> body)
        {:more, body, conn}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
