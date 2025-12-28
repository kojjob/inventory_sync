defmodule InventorySyncWeb.Api.V1.InventoryControllerTest do
  use InventorySyncWeb.ConnCase

  alias InventorySync.Accounts.{User, ApiToken}
  alias InventorySync.Inventory

  @channel_attrs %{
    name: "Test Shopify Store",
    platform: "shopify",
    credentials: %{"api_key" => "test_key", "api_secret" => "test_secret"},
    active: true
  }

  @product_attrs %{
    sku: "TEST-SKU-001",
    name: "Test Product",
    total_quantity: 100
  }

  setup do
    # Create a user for the API token
    {:ok, user} =
      %User{}
      |> User.email_changeset(%{email: "inventory-api-user@example.com"})
      |> InventorySync.Repo.insert()

    # Create API token with inventory scopes
    attrs = %{
      name: "Inventory API Token",
      scopes: ["read:inventory", "write:inventory"],
      user_id: user.id
    }

    {raw_token, api_token_struct} = ApiToken.build_token(attrs)
    {:ok, _saved_token} = InventorySync.Repo.insert(api_token_struct)

    # Create read-only API token
    read_only_attrs = %{
      name: "Read Only Token",
      scopes: ["read:inventory"],
      user_id: user.id
    }

    {read_only_raw_token, read_only_api_token_struct} = ApiToken.build_token(read_only_attrs)
    {:ok, _saved_read_only_token} = InventorySync.Repo.insert(read_only_api_token_struct)

    %{user: user, token: raw_token, read_only_token: read_only_raw_token}
  end

  describe "authentication" do
    test "returns 401 when no authorization header is present", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/inventory")
      assert json_response(conn, 401)["error"] == "unauthorized"
    end

    test "returns 401 when authorization header is invalid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid_token")
        |> get(~p"/api/v1/inventory")

      assert json_response(conn, 401)["error"] == "unauthorized"
    end
  end

  describe "index" do
    test "lists all inventory items with product and channel details", %{conn: conn, token: token} do
      # Create test data
      {:ok, channel} = Inventory.create_channel(@channel_attrs)
      {:ok, product} = Inventory.create_product(@product_attrs)

      {:ok, inventory_item} =
        Inventory.create_inventory_item(%{
          product_id: product.id,
          channel_id: channel.id,
          external_id: "ext-001",
          platform_sku: "SHOP-SKU-001",
          quantity: 50
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/inventory")

      response = json_response(conn, 200)
      assert is_list(response["data"])
      assert length(response["data"]) == 1

      item_data = hd(response["data"])
      assert item_data["id"] == inventory_item.id
      assert item_data["sku"] == "TEST-SKU-001"
      assert item_data["platform_sku"] == "SHOP-SKU-001"
      assert item_data["quantity"] == 50

      # Check product summary
      assert item_data["product"]["id"] == product.id
      assert item_data["product"]["sku"] == "TEST-SKU-001"
      assert item_data["product"]["name"] == "Test Product"

      # Check channel summary
      assert item_data["channel"]["id"] == channel.id
      assert item_data["channel"]["name"] == "Test Shopify Store"
      assert item_data["channel"]["platform"] == "shopify"
    end

    test "returns empty list when no inventory items exist", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/inventory")

      assert json_response(conn, 200)["data"] == []
    end

    test "lists multiple inventory items across channels", %{conn: conn, token: token} do
      # Create two channels
      {:ok, channel1} = Inventory.create_channel(@channel_attrs)

      {:ok, channel2} =
        Inventory.create_channel(%{
          @channel_attrs
          | name: "Second Store",
            platform: "amazon"
        })

      {:ok, product} = Inventory.create_product(@product_attrs)

      {:ok, _item1} =
        Inventory.create_inventory_item(%{
          product_id: product.id,
          channel_id: channel1.id,
          external_id: "ext-shop-001",
          platform_sku: "SHOP-001",
          quantity: 30
        })

      {:ok, _item2} =
        Inventory.create_inventory_item(%{
          product_id: product.id,
          channel_id: channel2.id,
          external_id: "ext-amzn-001",
          platform_sku: "AMZN-001",
          quantity: 70
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/inventory")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end
  end

  describe "update" do
    test "updates product quantity by SKU and returns product with inventory", %{
      conn: conn,
      token: token
    } do
      {:ok, channel} = Inventory.create_channel(@channel_attrs)
      {:ok, product} = Inventory.create_product(@product_attrs)

      {:ok, _inventory_item} =
        Inventory.create_inventory_item(%{
          product_id: product.id,
          channel_id: channel.id,
          external_id: "ext-update-001",
          platform_sku: "SHOP-SKU-001",
          quantity: 100
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/inventory/#{product.sku}", inventory: %{quantity: 75})

      response = json_response(conn, 200)
      assert response["data"]["sku"] == "TEST-SKU-001"
      assert response["data"]["name"] == "Test Product"
      assert response["data"]["total_quantity"] == 75

      # Check inventory allocation by channel is included
      assert is_list(response["data"]["inventory"])
    end

    test "returns 404 when product SKU does not exist", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/inventory/NONEXISTENT-SKU", inventory: %{quantity: 50})

      assert json_response(conn, 404)["error"] == "not_found"
    end

    test "returns 400 when inventory params are missing", %{conn: conn, token: token} do
      {:ok, product} = Inventory.create_product(@product_attrs)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/inventory/#{product.sku}")

      response = json_response(conn, 400)
      assert response["error"] == "bad_request"
      assert response["message"] == "Missing inventory parameters"
    end

    test "returns 403 when token lacks write:inventory scope", %{
      conn: conn,
      read_only_token: token
    } do
      {:ok, product} = Inventory.create_product(@product_attrs)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/inventory/#{product.sku}", inventory: %{quantity: 50})

      assert json_response(conn, 403)["error"] == "forbidden"
    end

    test "syncs inventory to all connected channels", %{conn: conn, token: token} do
      {:ok, channel1} = Inventory.create_channel(@channel_attrs)

      {:ok, channel2} =
        Inventory.create_channel(%{
          @channel_attrs
          | name: "Amazon Store",
            platform: "amazon"
        })

      {:ok, product} = Inventory.create_product(@product_attrs)

      {:ok, item1} =
        Inventory.create_inventory_item(%{
          product_id: product.id,
          channel_id: channel1.id,
          external_id: "ext-sync-shop-001",
          platform_sku: "SHOP-001",
          quantity: 100
        })

      {:ok, item2} =
        Inventory.create_inventory_item(%{
          product_id: product.id,
          channel_id: channel2.id,
          external_id: "ext-sync-amzn-001",
          platform_sku: "AMZN-001",
          quantity: 100
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/inventory/#{product.sku}", inventory: %{quantity: 50})

      response = json_response(conn, 200)
      assert response["data"]["total_quantity"] == 50

      # Verify inventory items were updated in database
      updated_item1 = Inventory.get_inventory_item!(item1.id)
      updated_item2 = Inventory.get_inventory_item!(item2.id)
      assert updated_item1.quantity == 50
      assert updated_item2.quantity == 50
    end
  end
end
