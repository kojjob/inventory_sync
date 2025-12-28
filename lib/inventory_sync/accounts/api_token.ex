defmodule InventorySync.Accounts.ApiToken do
  @moduledoc """
  Schema and functions for API token authentication.

  API tokens allow programmatic access to the REST API with scoped permissions.
  Tokens are stored as SHA256 hashes - the raw token is only shown once at creation.

  ## Scopes

  Tokens can have the following scopes:
  - `read:products` - Read product data
  - `write:products` - Create/update products
  - `read:inventory` - Read inventory levels
  - `write:inventory` - Update inventory quantities
  - `read:channels` - Read channel configurations
  - `write:channels` - Create/update channels
  - `read:reservations` - Read reservation data
  - `write:reservations` - Create/update reservations
  - `admin:all` - Full access to all resources

  ## Token Lifecycle

  1. Token created via `build_token/1` - returns raw token (show once) + struct
  2. Struct is inserted into database with hashed token
  3. API requests include raw token in Authorization header
  4. `verify_token/1` hashes the raw token and looks up the record
  5. `revoke/1` deletes the token when no longer needed
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias InventorySync.Accounts.User
  alias InventorySync.Repo

  @hash_algorithm :sha256
  @rand_size 32
  @default_expiry_days 90

  @valid_scope_pattern ~r/^(read|write|admin):(products|inventory|channels|reservations|all)$/

  schema "api_tokens" do
    field :token_hash, :binary
    field :name, :string
    field :scopes, {:array, :string}
    field :last_used_at, :utc_datetime
    field :expires_at, :utc_datetime

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for an API token.

  ## Required Fields
  - `name` - A descriptive name for the token (max 255 characters)
  - `scopes` - List of permission scopes (at least one required)

  ## Optional Fields
  - `user_id` - The user who owns this token
  - `expires_at` - When the token expires (defaults to 90 days)
  """
  def changeset(api_token, attrs) do
    api_token
    |> cast(attrs, [:name, :scopes, :user_id, :expires_at, :token_hash, :last_used_at])
    |> validate_required([:name, :scopes])
    |> validate_length(:name, max: 255)
    |> validate_scopes()
    |> foreign_key_constraint(:user_id)
  end

  defp validate_scopes(changeset) do
    case get_field(changeset, :scopes) do
      nil ->
        changeset

      [] ->
        add_error(changeset, :scopes, "must have at least one scope")

      scopes when is_list(scopes) ->
        Enum.reduce(scopes, changeset, fn scope, cs ->
          if Regex.match?(@valid_scope_pattern, scope) do
            cs
          else
            add_error(cs, :scopes, "invalid scope format: #{scope}")
          end
        end)

      _ ->
        changeset
    end
  end

  @doc """
  Builds a new API token with the given attributes.

  Returns a tuple of `{raw_token, %ApiToken{}}` where:
  - `raw_token` is the URL-safe base64 encoded token to give to the user (shown only once)
  - `%ApiToken{}` is the struct with `token_hash` set, ready for database insertion

  The raw token should be displayed to the user immediately after creation
  as it cannot be recovered from the stored hash.

  ## Example

      attrs = %{name: "My API Key", scopes: ["read:products"], user_id: 1}
      {raw_token, api_token} = ApiToken.build_token(attrs)
      {:ok, saved_token} = Repo.insert(api_token)
      # Give `raw_token` to user - it won't be retrievable later
  """
  def build_token(attrs) do
    raw_token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, raw_token)
    encoded_token = Base.url_encode64(raw_token, padding: false)

    expires_at =
      Map.get_lazy(attrs, :expires_at, fn ->
        DateTime.utc_now() |> DateTime.add(@default_expiry_days, :day)
      end)
      |> DateTime.truncate(:second)

    api_token = %__MODULE__{
      token_hash: hashed_token,
      name: Map.get(attrs, :name),
      scopes: Map.get(attrs, :scopes),
      user_id: Map.get(attrs, :user_id),
      expires_at: expires_at
    }

    {encoded_token, api_token}
  end

  @doc """
  Verifies a raw API token and returns the token record if valid.

  This function:
  1. Decodes and hashes the provided token
  2. Looks up the token in the database
  3. Checks if the token has expired
  4. Updates the `last_used_at` timestamp

  ## Returns

  - `{:ok, %ApiToken{}}` - Token is valid and not expired
  - `{:error, :invalid_token}` - Token format is invalid or couldn't be decoded
  - `{:error, :not_found}` - Token doesn't exist in database
  - `{:error, :token_expired}` - Token exists but has expired

  ## Example

      case ApiToken.verify_token(raw_token) do
        {:ok, token} -> # proceed with authorized request
        {:error, reason} -> # reject request
      end
  """
  def verify_token(raw_token) when is_binary(raw_token) do
    with {:ok, decoded} <- Base.url_decode64(raw_token, padding: false),
         hashed <- :crypto.hash(@hash_algorithm, decoded),
         %__MODULE__{} = token <- Repo.get_by(__MODULE__, token_hash: hashed) do
      cond do
        expired?(token) ->
          {:error, :token_expired}

        true ->
          # Update last_used_at
          {:ok, updated_token} =
            token
            |> Ecto.Changeset.change(%{
              last_used_at: DateTime.utc_now() |> DateTime.truncate(:second)
            })
            |> Repo.update()

          {:ok, updated_token}
      end
    else
      :error -> {:error, :invalid_token}
      nil -> {:error, :not_found}
    end
  end

  def verify_token(_), do: {:error, :invalid_token}

  defp expired?(%__MODULE__{expires_at: nil}), do: false

  defp expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  @doc """
  Checks if a token has a specific scope.

  The `admin:all` scope grants access to everything.

  ## Examples

      iex> has_scope?(%ApiToken{scopes: ["read:products"]}, "read:products")
      true

      iex> has_scope?(%ApiToken{scopes: ["admin:all"]}, "write:inventory")
      true

      iex> has_scope?(%ApiToken{scopes: ["read:products"]}, "write:products")
      false
  """
  def has_scope?(%__MODULE__{scopes: scopes}, required_scope) when is_list(scopes) do
    "admin:all" in scopes or required_scope in scopes
  end

  def has_scope?(_, _), do: false

  @doc """
  Revokes (deletes) an API token.

  ## Returns

  - `{:ok, %ApiToken{}}` - Token was successfully deleted
  - `{:error, changeset}` - Deletion failed

  ## Example

      {:ok, _deleted} = ApiToken.revoke(token)
  """
  def revoke(%__MODULE__{} = token) do
    Repo.delete(token)
  end

  @doc """
  Lists all API tokens for a user.

  Tokens are ordered by creation date (newest first).
  Does not return the raw token value (it's not stored).
  """
  def list_user_tokens(user_id) do
    from(t in __MODULE__,
      where: t.user_id == ^user_id,
      order_by: [desc: t.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single API token by ID, scoped to a user.

  Returns `nil` if the token doesn't exist or doesn't belong to the user.
  """
  def get_user_token(user_id, token_id) do
    Repo.get_by(__MODULE__, id: token_id, user_id: user_id)
  end
end
