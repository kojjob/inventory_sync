defmodule InventorySyncWeb.Plugs.ApiAuth do
  @moduledoc """
  Plug for API token authentication.

  This plug verifies Bearer tokens in the Authorization header and assigns
  the authenticated token and user to the connection.

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
  """

  import Plug.Conn

  alias InventorySync.Accounts.ApiToken
  alias InventorySync.Repo

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
  """
  def call(conn, opts) do
    with {:ok, raw_token} <- extract_token(conn),
         {:ok, api_token} <- verify_token(raw_token),
         {:ok, api_token} <- check_scope(api_token, opts),
         {:ok, api_token} <- preload_user(api_token) do
      conn
      |> assign(:api_token, api_token)
      |> assign(:current_user, api_token.user)
    else
      {:error, :missing_token} ->
        unauthorized(conn, "Authorization header is missing")

      {:error, :invalid_format} ->
        unauthorized(conn, "Authorization header must use Bearer token format")

      {:error, :invalid_token} ->
        unauthorized(conn, "API token is invalid")

      {:error, :not_found} ->
        unauthorized(conn, "API token is invalid or does not exist")

      {:error, :token_expired} ->
        unauthorized(conn, "API token has expired")

      {:error, :insufficient_scope} ->
        forbidden(conn, "Token does not have the required scope")
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
