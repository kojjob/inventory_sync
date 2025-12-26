defmodule InventorySyncWeb.Plugs.ApiAuthTest do
  use InventorySyncWeb.ConnCase, async: true

  alias InventorySync.Accounts.ApiToken
  alias InventorySync.Accounts.User
  alias InventorySyncWeb.Plugs.ApiAuth

  describe "init/1" do
    test "accepts scope option" do
      assert ApiAuth.init(scope: "read:products") == %{scope: "read:products"}
    end

    test "accepts empty options" do
      assert ApiAuth.init([]) == %{}
    end
  end

  describe "call/2 with valid token" do
    setup do
      {:ok, user} =
        %User{}
        |> User.email_changeset(%{email: "api-user@example.com"})
        |> InventorySync.Repo.insert()

      attrs = %{
        name: "Test API Token",
        scopes: ["read:products", "write:inventory"],
        user_id: user.id
      }

      {raw_token, api_token_struct} = ApiToken.build_token(attrs)
      {:ok, saved_token} = InventorySync.Repo.insert(api_token_struct)

      %{user: user, raw_token: raw_token, saved_token: saved_token}
    end

    test "assigns api_token and current_user when valid token provided", %{
      raw_token: raw_token,
      user: user
    } do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{raw_token}")
        |> ApiAuth.call(%{})

      refute conn.halted
      assert conn.assigns[:api_token] != nil
      assert conn.assigns[:api_token].name == "Test API Token"
      assert conn.assigns[:current_user].id == user.id
    end

    test "accepts token with required scope", %{raw_token: raw_token} do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{raw_token}")
        |> ApiAuth.call(%{scope: "read:products"})

      refute conn.halted
      assert conn.assigns[:api_token] != nil
    end

    test "rejects token missing required scope", %{raw_token: raw_token} do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{raw_token}")
        |> ApiAuth.call(%{scope: "admin:all"})

      assert conn.halted
      assert conn.status == 403

      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "forbidden"
      assert body["message"] =~ "scope"
    end

    test "admin:all scope grants access to any required scope" do
      {:ok, user} =
        %User{}
        |> User.email_changeset(%{email: "admin@example.com"})
        |> InventorySync.Repo.insert()

      attrs = %{
        name: "Admin Token",
        scopes: ["admin:all"],
        user_id: user.id
      }

      {raw_token, api_token_struct} = ApiToken.build_token(attrs)
      {:ok, _saved_token} = InventorySync.Repo.insert(api_token_struct)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{raw_token}")
        |> ApiAuth.call(%{scope: "write:reservations"})

      refute conn.halted
      assert conn.assigns[:api_token] != nil
    end
  end

  describe "call/2 with invalid or missing token" do
    test "returns 401 when authorization header is missing" do
      conn =
        build_conn()
        |> ApiAuth.call(%{})

      assert conn.halted
      assert conn.status == 401

      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "unauthorized"
      assert body["message"] =~ "missing"
    end

    test "returns 401 when authorization header has wrong format" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Basic some-token")
        |> ApiAuth.call(%{})

      assert conn.halted
      assert conn.status == 401

      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "unauthorized"
      assert body["message"] =~ "Bearer"
    end

    test "returns 401 when token is invalid" do
      # Use characters that are NOT valid URL-safe base64 to trigger :invalid_token
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer !!not-valid-base64!!")
        |> ApiAuth.call(%{})

      assert conn.halted
      assert conn.status == 401

      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "unauthorized"
      assert body["message"] =~ "invalid"
    end

    test "returns 401 when token does not exist in database" do
      # Generate a valid-looking but non-existent token
      fake_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{fake_token}")
        |> ApiAuth.call(%{})

      assert conn.halted
      assert conn.status == 401

      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "unauthorized"
    end

    test "returns 401 when token is expired" do
      {:ok, user} =
        %User{}
        |> User.email_changeset(%{email: "expired@example.com"})
        |> InventorySync.Repo.insert()

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

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{raw_token}")
        |> ApiAuth.call(%{})

      assert conn.halted
      assert conn.status == 401

      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "unauthorized"
      assert body["message"] =~ "expired"
    end
  end

  describe "call/2 preloads user" do
    test "preloads user association on api_token" do
      {:ok, user} =
        %User{}
        |> User.email_changeset(%{email: "preload-test@example.com"})
        |> InventorySync.Repo.insert()

      attrs = %{
        name: "Preload Test Token",
        scopes: ["read:products"],
        user_id: user.id
      }

      {raw_token, api_token_struct} = ApiToken.build_token(attrs)
      {:ok, _saved_token} = InventorySync.Repo.insert(api_token_struct)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{raw_token}")
        |> ApiAuth.call(%{})

      refute conn.halted
      # User should be preloaded, not requiring another DB query
      assert conn.assigns[:current_user].email == "preload-test@example.com"
    end
  end

  describe "rate limiting" do
    test "allows requests within rate limit" do
      # Create a valid token
      {:ok, user} =
        %User{}
        |> User.email_changeset(%{email: "rate-limit@example.com"})
        |> InventorySync.Repo.insert()

      attrs = %{
        name: "Rate Limit Token",
        scopes: ["read:products"],
        user_id: user.id
      }

      {raw_token, api_token_struct} = ApiToken.build_token(attrs)
      {:ok, _saved_token} = InventorySync.Repo.insert(api_token_struct)

      # Make multiple requests within the limit (5 per minute)
      for _ <- 1..4 do
        conn =
          build_conn()
          |> put_req_header("authorization", "Bearer #{raw_token}")
          |> ApiAuth.call(%{})

        refute conn.halted
        assert conn.assigns[:api_token] != nil
      end
    end

    test "returns 429 when rate limit exceeded with invalid tokens" do
      fake_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

      # Make requests to exceed the rate limit (5 failed attempts)
      # The 6th request should be rate limited
      for i <- 1..6 do
        conn =
          build_conn()
          |> put_req_header("authorization", "Bearer #{fake_token}")
          |> ApiAuth.call(%{})

        assert conn.halted

        if i <= 5 do
          # First 5 attempts should return 401 (unauthorized)
          assert conn.status == 401
          body = Jason.decode!(conn.resp_body)
          assert body["error"] == "unauthorized"
        else
          # 6th attempt should return 429 (rate limited)
          assert conn.status == 429
          body = Jason.decode!(conn.resp_body)
          assert body["error"] == "too_many_requests"
          assert body["message"] =~ "Rate limit"
        end
      end
    end

    test "rate limiting is per IP address" do
      fake_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

      # Make 5 requests from first IP
      for _ <- 1..5 do
        conn =
          build_conn()
          |> put_req_header("authorization", "Bearer #{fake_token}")
          |> ApiAuth.call(%{})

        assert conn.halted
        assert conn.status == 401
      end

      # 6th request from same IP should be rate limited
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{fake_token}")
        |> ApiAuth.call(%{})

      assert conn.halted
      assert conn.status == 429

      # But request from different IP (simulated by X-Forwarded-For) should work
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{fake_token}")
        |> put_req_header("x-forwarded-for", "192.168.1.100")
        |> ApiAuth.call(%{})

      assert conn.halted
      # Should get 401 (unauthorized), not 429 (rate limited)
      assert conn.status == 401
    end

    test "successful authentication does not count toward rate limit" do
      {:ok, user} =
        %User{}
        |> User.email_changeset(%{email: "success-rate@example.com"})
        |> InventorySync.Repo.insert()

      attrs = %{
        name: "Success Rate Token",
        scopes: ["read:products"],
        user_id: user.id
      }

      {raw_token, api_token_struct} = ApiToken.build_token(attrs)
      {:ok, _saved_token} = InventorySync.Repo.insert(api_token_struct)

      # Make many successful requests - none should be rate limited
      for _ <- 1..10 do
        conn =
          build_conn()
          |> put_req_header("authorization", "Bearer #{raw_token}")
          |> ApiAuth.call(%{})

        refute conn.halted
        assert conn.assigns[:api_token] != nil
      end
    end
  end
end
