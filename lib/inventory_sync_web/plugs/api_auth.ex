defmodule InventorySyncWeb.Plugs.ApiAuth do
  @moduledoc """
  Plug for API token authentication.

  This plug verifies Bearer tokens in the Authorization header and assigns
  the authenticated token and user to the connection.

  ## Rate Limiting

  To protect against timing attacks and brute force attempts, this plug
  implements rate limiting on failed authentication attempts. By default:
  - 5 failed attempts per IP address per minute
  - 429 Too Many Requests response when limit exceeded

  ## Usage

  Add to your router pipeline:

      pipeline :api_auth do
        plug InventorySyncWeb.Plugs.ApiAuth
      end

  Or with a required scope:

      pipeline :api_write do
        plug InventorySyncWeb.Plugs.ApiAuth, scope: "write:products"
      end

  ## Assigns

  On successful authentication, the plug assigns:
  - `:api_token` - The verified `%ApiToken{}` struct
  - `:current_user` - The user associated with the token

  ## Error Responses

  - `401 Unauthorized` - Missing, invalid, or expired token
  - `403 Forbidden` - Token lacks required scope
  - `429 Too Many Requests` - Rate limit exceeded
  """

  import Plug.Conn

  alias InventorySync.Accounts.ApiToken
  alias InventorySync.Repo

  # Rate limit: 5 failed attempts per minute per IP
  @rate_limit_scale 60_000  # 1 minute in milliseconds
  @rate_limit_limit 5       # 5 attempts

  @doc """
  Initializes the plug with options.

  ## Options

  - `:scope` - A required scope string (e.g., "read:products")
               If provided, the token must have this scope or "admin:all"
  """
  def init(opts) do
    case Keyword.get(opts, :scope) do
      nil -> %{}
      scope -> %{scope: scope}
    end
  end

  @doc """
  Authenticates the request using Bearer token authentication.

  Extracts the token from the Authorization header, verifies it,
  optionally checks for required scope, and assigns the token
  and user to the connection.

  Rate limiting is applied per IP address for failed authentication attempts.
  """
  def call(conn, opts) do
    client_ip = get_client_ip(conn)
    
    # First, check if this IP has exceeded rate limits
    case check_if_rate_limited(client_ip) do
      :ok ->
        # Process authentication
        case do_auth(conn, opts) do
          {:ok, conn} ->
            # Success - don't increment rate limit counter
            conn
          
          {:error, conn} ->
            # Failed - increment rate limit counter
            record_failed_attempt(client_ip)
            conn
        end
      
      :rate_limited ->
        rate_limited(conn)
    end
  end

  defp do_auth(conn, opts) do
    with {:ok, raw_token} <- extract_token(conn),
         {:ok, api_token} <- verify_token(raw_token),
         {:ok, api_token} <- check_scope(api_token, opts),
         {:ok, api_token} <- preload_user(api_token) do
      conn =
        conn
        |> assign(:api_token, api_token)
        |> assign(:current_user, api_token.user)
      
      {:ok, conn}
    else
      {:error, :missing_token} ->
        {:error, unauthorized(conn, "Authorization header is missing")}

      {:error, :invalid_format} ->
        {:error, unauthorized(conn, "Authorization header must use Bearer scheme")}

      {:error, :invalid_token} ->
        {:error, unauthorized(conn, "Token is invalid")}

      {:error, :not_found} ->
        {:error, unauthorized(conn, "Token not found")}

      {:error, :token_expired} ->
        {:error, unauthorized(conn, "Token has expired")}

      {:error, :insufficient_scope} ->
        {:error, forbidden(conn, "Token lacks required scope")}
    end
  end

  # Extracts the Bearer token from the Authorization header
  defp extract_token(conn) do
    case get_req_header(conn, "authorization") do
      [] ->
        {:error, :missing_token}

      [auth_header | _] ->
        case String.split(auth_header, " ", parts: 2) do
          ["Bearer", token] when byte_size(token) > 0 ->
            {:ok, token}

          _ ->
            {:error, :invalid_format}
        end
    end
  end

  # Verifies the token using the ApiToken module
  defp verify_token(raw_token) do
    ApiToken.verify_token(raw_token)
  end

  # Checks if the token has the required scope (if specified)
  defp check_scope(api_token, %{scope: required_scope}) do
    if ApiToken.has_scope?(api_token, required_scope) do
      {:ok, api_token}
    else
      {:error, :insufficient_scope}
    end
  end

  defp check_scope(api_token, _opts), do: {:ok, api_token}

  # Preloads the user association
  defp preload_user(api_token) do
    {:ok, Repo.preload(api_token, :user)}
  end

  # Gets the client IP address from the connection
  defp get_client_ip(conn) do
    # Check for X-Forwarded-For header (when behind proxy/load balancer)
    # Use the rightmost IP (closest to server) which is more trustworthy
    case get_req_header(conn, "x-forwarded-for") do
      [ip_string | _] ->
        ip_string
        |> String.split(",")
        |> List.last()  # Use rightmost IP instead of first
        |> String.trim()
        |> sanitize_ip()

      [] ->
        # Fall back to remote_ip from the connection
        conn.remote_ip
        |> :inet.ntoa()
        |> to_string()
        |> sanitize_ip()
    end
  end

  # Sanitizes IP address to prevent injection attacks
  # Returns a safe string suitable for use in bucket keys
  defp sanitize_ip(ip_string) when is_binary(ip_string) do
    # Only allow valid IPv4 and IPv6 characters
    # This prevents special characters that could interfere with rate limiting
    case :inet.parse_address(String.to_charlist(ip_string)) do
      {:ok, _parsed_ip} ->
        # Valid IP address, safe to use
        ip_string
      
      {:error, _} ->
        # Invalid IP, use a safe fallback
        # Hash it to create a consistent identifier
        :crypto.hash(:sha256, ip_string)
        |> Base.encode16(case: :lower)
    end
  end

  defp sanitize_ip(ip_string), do: "unknown"

  # Checks if the IP address has exceeded the rate limit (without incrementing)
  defp check_if_rate_limited(client_ip) do
    bucket_key = "api_auth:#{client_ip}"
    
    # Use inspect_bucket to check current count without incrementing
    case Hammer.inspect_bucket(bucket_key, @rate_limit_scale, @rate_limit_limit) do
      {:ok, {count, _count_remaining, _ms_to_next_bucket, _created_at, _updated_at}} ->
        if count >= @rate_limit_limit do
          :rate_limited
        else
          :ok
        end
      
      # If bucket doesn't exist yet, allow the request
      {:error, _} ->
        :ok
    end
  end

  # Records a failed authentication attempt
  defp record_failed_attempt(client_ip) do
    bucket_key = "api_auth:#{client_ip}"
    
    # Increment the counter for failed attempts
    case Hammer.check_rate(bucket_key, @rate_limit_scale, @rate_limit_limit) do
      {:allow, _count} ->
        :ok
      
      {:deny, _limit} ->
        # Already at limit, but that's fine - we're just recording
        :ok
      
      {:error, reason} ->
        # Log error but don't fail the request
        require Logger
        Logger.warning("Failed to record rate limit attempt for #{client_ip}: #{inspect(reason)}")
        :ok
    end
  end

  # Returns a 429 Too Many Requests response
  defp rate_limited(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      429,
      Jason.encode!(%{
        error: "too_many_requests",
        message: "Rate limit exceeded. Please try again later."
      })
    )
    |> halt()
  end

  # Returns a 401 Unauthorized response
  defp unauthorized(conn, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{error: "unauthorized", message: message}))
    |> halt()
  end

  # Returns a 403 Forbidden response
  defp forbidden(conn, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(403, Jason.encode!(%{error: "forbidden", message: message}))
    |> halt()
  end
end
