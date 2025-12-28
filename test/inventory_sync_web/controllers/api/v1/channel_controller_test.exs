defmodule InventorySyncWeb.Api.V1.ChannelControllerTest do
  use InventorySyncWeb.ConnCase

  alias InventorySync.Accounts.{User, ApiToken}
  alias InventorySync.Inventory

  @valid_attrs %{
    name: "My Shopify Store",
    platform: "shopify",
    credentials: %{"api_key" => "test_key", "api_secret" => "test_secret"},
    active: true
  }
  @invalid_attrs %{name: nil, platform: nil}

  setup do
    # Create a user for the API token
    {:ok, user} =
      %User{}
      |> User.email_changeset(%{email: "api-user@example.com"})
      |> InventorySync.Repo.insert()

    # Create API token with full channel scopes
    attrs = %{
      name: "Test API Token",
      scopes: ["read:channels", "write:channels"],
      user_id: user.id
    }

    {raw_token, api_token_struct} = ApiToken.build_token(attrs)
    {:ok, _saved_token} = InventorySync.Repo.insert(api_token_struct)

    # Create read-only API token
    read_only_attrs = %{
      name: "Read Only Token",
      scopes: ["read:channels"],
      user_id: user.id
    }

    {read_only_raw_token, read_only_api_token_struct} = ApiToken.build_token(read_only_attrs)
    {:ok, _saved_read_only_token} = InventorySync.Repo.insert(read_only_api_token_struct)

    %{user: user, token: raw_token, read_only_token: read_only_raw_token}
  end

  describe "authentication" do
    test "returns 401 when no authorization header is present", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/channels")
      assert json_response(conn, 401)["error"] == "unauthorized"
    end

    test "returns 401 when authorization header is invalid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid_token")
        |> get(~p"/api/v1/channels")

      assert json_response(conn, 401)["error"] == "unauthorized"
    end
  end

  describe "index" do
    test "lists all channels", %{conn: conn, token: token} do
      {:ok, channel} = Inventory.create_channel(@valid_attrs)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/channels")

      response = json_response(conn, 200)
      assert is_list(response["data"])
      assert length(response["data"]) == 1

      channel_data = hd(response["data"])
      assert channel_data["id"] == channel.id
      assert channel_data["name"] == "My Shopify Store"
      assert channel_data["platform"] == "shopify"
      assert channel_data["active"] == true
      # Credentials should NOT be exposed in the response
      refute Map.has_key?(channel_data, "credentials")
    end

    test "returns empty list when no channels exist", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/channels")

      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "show" do
    test "returns a channel when it exists", %{conn: conn, token: token} do
      {:ok, channel} = Inventory.create_channel(@valid_attrs)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/channels/#{channel.id}")

      response = json_response(conn, 200)
      assert response["data"]["id"] == channel.id
      assert response["data"]["name"] == "My Shopify Store"
      assert response["data"]["platform"] == "shopify"
      assert response["data"]["active"] == true
      # Credentials should NOT be exposed in the response
      refute Map.has_key?(response["data"], "credentials")
    end

    test "returns 404 when channel does not exist", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/channels/99999")

      assert json_response(conn, 404)["error"] == "not_found"
    end
  end

  describe "create" do
    test "creates a channel with valid data", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/channels", channel: @valid_attrs)

      response = json_response(conn, 201)
      assert response["data"]["name"] == "My Shopify Store"
      assert response["data"]["platform"] == "shopify"
      assert response["data"]["active"] == true
      # Credentials should NOT be exposed in the response
      refute Map.has_key?(response["data"], "credentials")

      # Verify channel was actually created in database
      assert Inventory.get_channel!(response["data"]["id"])
    end

    test "returns 422 with invalid data", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/channels", channel: @invalid_attrs)

      response = json_response(conn, 422)
      assert response["errors"] != %{}
    end

    test "returns 422 with invalid platform", %{conn: conn, token: token} do
      invalid_platform_attrs = %{name: "Test Store", platform: "invalid_platform"}

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/channels", channel: invalid_platform_attrs)

      response = json_response(conn, 422)
      assert response["errors"] != %{}
    end

    test "returns 403 when token lacks write scope", %{conn: conn, read_only_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/channels", channel: @valid_attrs)

      assert json_response(conn, 403)["error"] == "forbidden"
    end
  end

  describe "update" do
    test "updates a channel with valid data", %{conn: conn, token: token} do
      {:ok, channel} = Inventory.create_channel(@valid_attrs)

      update_attrs = %{name: "Updated Store Name", active: false}

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/channels/#{channel.id}", channel: update_attrs)

      response = json_response(conn, 200)
      assert response["data"]["id"] == channel.id
      assert response["data"]["name"] == "Updated Store Name"
      assert response["data"]["active"] == false
      # Platform should remain unchanged
      assert response["data"]["platform"] == "shopify"
    end

    test "returns 404 when channel does not exist", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/channels/99999", channel: %{name: "New Name"})

      assert json_response(conn, 404)["error"] == "not_found"
    end

    test "returns 422 with invalid data", %{conn: conn, token: token} do
      {:ok, channel} = Inventory.create_channel(@valid_attrs)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/channels/#{channel.id}", channel: %{name: nil})

      response = json_response(conn, 422)
      assert response["errors"] != %{}
    end

    test "returns 403 when token lacks write scope", %{conn: conn, read_only_token: token} do
      {:ok, channel} = Inventory.create_channel(@valid_attrs)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/channels/#{channel.id}", channel: %{name: "New Name"})

      assert json_response(conn, 403)["error"] == "forbidden"
    end
  end

  describe "delete" do
    test "deletes a channel", %{conn: conn, token: token} do
      {:ok, channel} = Inventory.create_channel(@valid_attrs)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/channels/#{channel.id}")

      assert response(conn, 204)

      # Verify channel was actually deleted
      assert_raise Ecto.NoResultsError, fn ->
        Inventory.get_channel!(channel.id)
      end
    end

    test "returns 404 when channel does not exist", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/channels/99999")

      assert json_response(conn, 404)["error"] == "not_found"
    end

    test "returns 403 when token lacks write scope", %{conn: conn, read_only_token: token} do
      {:ok, channel} = Inventory.create_channel(@valid_attrs)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/channels/#{channel.id}")

      assert json_response(conn, 403)["error"] == "forbidden"
    end
  end
end
