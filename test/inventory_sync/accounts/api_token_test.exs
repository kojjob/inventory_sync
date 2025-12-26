defmodule InventorySync.Accounts.ApiTokenTest do
  use InventorySync.DataCase, async: true

  alias InventorySync.Accounts.ApiToken
  alias InventorySync.Accounts.User

  describe "schema" do
    test "has expected fields" do
      fields = ApiToken.__schema__(:fields)

      assert :id in fields
      assert :token_hash in fields
      assert :name in fields
      assert :scopes in fields
      assert :last_used_at in fields
      assert :expires_at in fields
      assert :user_id in fields
      assert :inserted_at in fields
      assert :updated_at in fields
    end

    test "belongs_to user association" do
      assocs = ApiToken.__schema__(:associations)
      assert :user in assocs
    end
  end

  describe "changeset/2" do
    setup do
      {:ok, user} =
        %User{}
        |> User.email_changeset(%{email: "test@example.com"})
        |> InventorySync.Repo.insert()

      %{user: user}
    end

    test "valid changeset with required fields", %{user: user} do
      attrs = %{
        name: "My API Token",
        scopes: ["read:products", "write:inventory"],
        user_id: user.id
      }

      changeset = ApiToken.changeset(%ApiToken{}, attrs)
      assert changeset.valid?
    end

    test "requires name" do
      changeset = ApiToken.changeset(%ApiToken{}, %{scopes: ["read:products"]})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires at least one scope" do
      changeset = ApiToken.changeset(%ApiToken{}, %{name: "Test", scopes: []})
      assert %{scopes: ["must have at least one scope"]} = errors_on(changeset)
    end

    test "validates scope format" do
      changeset =
        ApiToken.changeset(%ApiToken{}, %{
          name: "Test",
          scopes: ["invalid_scope"]
        })

      assert %{scopes: ["invalid scope format: invalid_scope"]} = errors_on(changeset)
    end

    test "accepts valid scope formats" do
      valid_scopes = [
        "read:products",
        "write:inventory",
        "read:channels",
        "write:channels",
        "read:reservations",
        "write:reservations",
        "admin:all"
      ]

      changeset =
        ApiToken.changeset(%ApiToken{}, %{
          name: "Test",
          scopes: valid_scopes
        })

      refute Map.has_key?(errors_on(changeset), :scopes)
    end

    test "validates name length" do
      changeset =
        ApiToken.changeset(%ApiToken{}, %{
          name: String.duplicate("a", 256),
          scopes: ["read:products"]
        })

      assert %{name: ["should be at most 255 character(s)"]} = errors_on(changeset)
    end
  end

  describe "build_token/1" do
    setup do
      {:ok, user} =
        %User{}
        |> User.email_changeset(%{email: "test@example.com"})
        |> InventorySync.Repo.insert()

      %{user: user}
    end

    test "generates a token and returns both raw and hashed versions", %{user: user} do
      attrs = %{
        name: "My API Token",
        scopes: ["read:products"],
        user_id: user.id
      }

      {raw_token, api_token_struct} = ApiToken.build_token(attrs)

      # Raw token should be URL-safe base64 encoded
      assert is_binary(raw_token)
      assert {:ok, _} = Base.url_decode64(raw_token, padding: false)

      # Struct should have hashed token
      assert is_binary(api_token_struct.token_hash)
      assert api_token_struct.name == "My API Token"
      assert api_token_struct.scopes == ["read:products"]
      assert api_token_struct.user_id == user.id
    end

    test "hashed token cannot be reversed to raw token", %{user: user} do
      attrs = %{
        name: "Test Token",
        scopes: ["read:products"],
        user_id: user.id
      }

      {raw_token1, struct1} = ApiToken.build_token(attrs)
      {raw_token2, struct2} = ApiToken.build_token(attrs)

      # Each call generates different tokens
      refute raw_token1 == raw_token2
      refute struct1.token_hash == struct2.token_hash
    end

    test "sets default expiration to 90 days from now", %{user: user} do
      attrs = %{
        name: "Test Token",
        scopes: ["read:products"],
        user_id: user.id
      }

      {_raw_token, api_token_struct} = ApiToken.build_token(attrs)

      # Should expire approximately 90 days from now
      expected_expiry = DateTime.utc_now() |> DateTime.add(90, :day)
      diff = DateTime.diff(api_token_struct.expires_at, expected_expiry, :second)
      # Within 5 seconds tolerance
      assert abs(diff) < 5
    end

    test "allows custom expiration", %{user: user} do
      custom_expiry = DateTime.utc_now() |> DateTime.add(30, :day)

      attrs = %{
        name: "Test Token",
        scopes: ["read:products"],
        user_id: user.id,
        expires_at: custom_expiry
      }

      {_raw_token, api_token_struct} = ApiToken.build_token(attrs)

      diff = DateTime.diff(api_token_struct.expires_at, custom_expiry, :second)
      # Truncation to seconds can cause up to 1 second difference
      assert abs(diff) <= 1
    end
  end

  describe "verify_token/1" do
    setup do
      {:ok, user} =
        %User{}
        |> User.email_changeset(%{email: "test@example.com"})
        |> InventorySync.Repo.insert()

      %{user: user}
    end

    test "returns token struct when valid token provided", %{user: user} do
      attrs = %{
        name: "Test Token",
        scopes: ["read:products"],
        user_id: user.id
      }

      {raw_token, api_token_struct} = ApiToken.build_token(attrs)
      {:ok, saved_token} = InventorySync.Repo.insert(api_token_struct)

      assert {:ok, found_token} = ApiToken.verify_token(raw_token)
      assert found_token.id == saved_token.id
      assert found_token.name == "Test Token"
    end

    test "returns error for invalid token" do
      assert {:error, :invalid_token} = ApiToken.verify_token("!!not-valid-base64!!")
    end

    test "returns error for non-existent token" do
      # Generate a valid-looking but non-existent token
      fake_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
      assert {:error, :not_found} = ApiToken.verify_token(fake_token)
    end

    test "returns error for expired token", %{user: user} do
      # Create token that expired yesterday
      expired_at = DateTime.utc_now() |> DateTime.add(-1, :day)

      attrs = %{
        name: "Expired Token",
        scopes: ["read:products"],
        user_id: user.id,
        expires_at: expired_at
      }

      {raw_token, api_token_struct} = ApiToken.build_token(attrs)
      {:ok, _saved_token} = InventorySync.Repo.insert(api_token_struct)

      assert {:error, :token_expired} = ApiToken.verify_token(raw_token)
    end

    test "updates last_used_at on successful verification", %{user: user} do
      attrs = %{
        name: "Test Token",
        scopes: ["read:products"],
        user_id: user.id
      }

      {raw_token, api_token_struct} = ApiToken.build_token(attrs)
      {:ok, saved_token} = InventorySync.Repo.insert(api_token_struct)

      assert is_nil(saved_token.last_used_at)

      {:ok, verified_token} = ApiToken.verify_token(raw_token)
      assert verified_token.last_used_at != nil
    end
  end

  describe "has_scope?/2" do
    test "returns true when token has exact scope" do
      token = %ApiToken{scopes: ["read:products", "write:inventory"]}

      assert ApiToken.has_scope?(token, "read:products")
      assert ApiToken.has_scope?(token, "write:inventory")
    end

    test "returns false when token lacks scope" do
      token = %ApiToken{scopes: ["read:products"]}

      refute ApiToken.has_scope?(token, "write:products")
      refute ApiToken.has_scope?(token, "admin:all")
    end

    test "admin:all grants all scopes" do
      token = %ApiToken{scopes: ["admin:all"]}

      assert ApiToken.has_scope?(token, "read:products")
      assert ApiToken.has_scope?(token, "write:inventory")
      assert ApiToken.has_scope?(token, "admin:all")
    end
  end

  describe "revoke/1" do
    setup do
      {:ok, user} =
        %User{}
        |> User.email_changeset(%{email: "test@example.com"})
        |> InventorySync.Repo.insert()

      %{user: user}
    end

    test "deletes the token from database", %{user: user} do
      attrs = %{
        name: "Test Token",
        scopes: ["read:products"],
        user_id: user.id
      }

      {_raw_token, api_token_struct} = ApiToken.build_token(attrs)
      {:ok, saved_token} = InventorySync.Repo.insert(api_token_struct)

      assert {:ok, _deleted} = ApiToken.revoke(saved_token)
      assert InventorySync.Repo.get(ApiToken, saved_token.id) == nil
    end
  end
end
