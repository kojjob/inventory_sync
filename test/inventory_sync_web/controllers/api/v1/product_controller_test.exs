defmodule InventorySyncWeb.Api.V1.ProductControllerTest do
  use InventorySyncWeb.ConnCase, async: true

  alias InventorySync.Accounts.ApiToken
  alias InventorySync.Accounts.User
  alias InventorySync.Inventory
  alias InventorySync.Inventory.Product

  setup do
    # Create a user for the API token
    {:ok, user} =
      %User{}
      |> User.email_changeset(%{email: "api-user@example.com"})
      |> InventorySync.Repo.insert()

    # Create an API token with product scopes
    attrs = %{
      name: "Test API Token",
      scopes: ["read:products", "write:products"],
      user_id: user.id
    }

    {raw_token, api_token_struct} = ApiToken.build_token(attrs)
    {:ok, _saved_token} = InventorySync.Repo.insert(api_token_struct)

    # Create a token with only read scope
    read_only_attrs = %{
      name: "Read Only Token",
      scopes: ["read:products"],
      user_id: user.id
    }

    {read_only_token, read_only_struct} = ApiToken.build_token(read_only_attrs)
    {:ok, _} = InventorySync.Repo.insert(read_only_struct)

    %{
      user: user,
      token: raw_token,
      read_only_token: read_only_token
    }
  end

  describe "authentication" do
    test "returns 401 when no authorization header is provided" do
      conn = build_conn()
      conn = get(conn, ~p"/api/v1/products")

      assert json_response(conn, 401)["error"] == "unauthorized"
    end

    test "returns 401 when token is invalid" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer invalid_token")
        |> get(~p"/api/v1/products")

      assert json_response(conn, 401)["error"] == "unauthorized"
    end
  end

  describe "index" do
    test "lists all products when authenticated", %{token: token} do
      # Create some products
      {:ok, product1} = Inventory.create_product(%{sku: "SKU-001", name: "Product 1", total_quantity: 100})
      {:ok, product2} = Inventory.create_product(%{sku: "SKU-002", name: "Product 2", total_quantity: 200})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/products")

      assert %{"data" => products} = json_response(conn, 200)
      assert length(products) == 2

      skus = Enum.map(products, & &1["sku"])
      assert "SKU-001" in skus
      assert "SKU-002" in skus
    end

    test "returns empty list when no products exist", %{token: token} do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/products")

      assert %{"data" => []} = json_response(conn, 200)
    end
  end

  describe "show" do
    test "returns product when it exists", %{token: token} do
      {:ok, product} = Inventory.create_product(%{sku: "SKU-001", name: "Test Product", total_quantity: 50})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/products/#{product.id}")

      assert %{"data" => returned_product} = json_response(conn, 200)
      assert returned_product["id"] == product.id
      assert returned_product["sku"] == "SKU-001"
      assert returned_product["name"] == "Test Product"
      assert returned_product["total_quantity"] == 50
    end

    test "returns 404 when product does not exist", %{token: token} do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/products/999999")

      assert json_response(conn, 404)["error"] == "not_found"
    end
  end

  describe "create" do
    test "creates product with valid data", %{token: token} do
      product_params = %{
        sku: "NEW-SKU-001",
        name: "New Product",
        total_quantity: 75
      }

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/v1/products", %{product: product_params})

      assert %{"data" => created_product} = json_response(conn, 201)
      assert created_product["sku"] == "NEW-SKU-001"
      assert created_product["name"] == "New Product"
      assert created_product["total_quantity"] == 75
      assert created_product["id"] != nil
    end

    test "returns 422 with invalid data", %{token: token} do
      product_params = %{
        sku: "",
        name: ""
      }

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/v1/products", %{product: product_params})

      assert %{"errors" => errors} = json_response(conn, 422)
      assert errors != %{}
    end

    test "returns 403 when token lacks write scope", %{read_only_token: token} do
      product_params = %{
        sku: "NEW-SKU-001",
        name: "New Product",
        total_quantity: 75
      }

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/v1/products", %{product: product_params})

      assert json_response(conn, 403)["error"] == "forbidden"
    end
  end

  describe "update" do
    test "updates product with valid data", %{token: token} do
      {:ok, product} = Inventory.create_product(%{sku: "SKU-001", name: "Original", total_quantity: 50})

      update_params = %{
        name: "Updated Product",
        total_quantity: 100
      }

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> put_req_header("content-type", "application/json")
        |> put(~p"/api/v1/products/#{product.id}", %{product: update_params})

      assert %{"data" => updated_product} = json_response(conn, 200)
      assert updated_product["name"] == "Updated Product"
      assert updated_product["total_quantity"] == 100
      assert updated_product["sku"] == "SKU-001"
    end

    test "returns 404 when product does not exist", %{token: token} do
      update_params = %{name: "Updated"}

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> put_req_header("content-type", "application/json")
        |> put(~p"/api/v1/products/999999", %{product: update_params})

      assert json_response(conn, 404)["error"] == "not_found"
    end

    test "returns 422 with invalid data", %{token: token} do
      {:ok, product} = Inventory.create_product(%{sku: "SKU-001", name: "Original", total_quantity: 50})

      update_params = %{sku: ""}

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> put_req_header("content-type", "application/json")
        |> put(~p"/api/v1/products/#{product.id}", %{product: update_params})

      assert %{"errors" => _errors} = json_response(conn, 422)
    end

    test "returns 403 when token lacks write scope", %{read_only_token: token} do
      {:ok, product} = Inventory.create_product(%{sku: "SKU-001", name: "Original", total_quantity: 50})

      update_params = %{name: "Updated"}

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> put_req_header("content-type", "application/json")
        |> put(~p"/api/v1/products/#{product.id}", %{product: update_params})

      assert json_response(conn, 403)["error"] == "forbidden"
    end
  end

  describe "delete" do
    test "deletes product successfully", %{token: token} do
      {:ok, product} = Inventory.create_product(%{sku: "SKU-001", name: "To Delete", total_quantity: 50})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/products/#{product.id}")

      assert response(conn, 204)

      # Verify product is deleted
      assert InventorySync.Repo.get(Product, product.id) == nil
    end

    test "returns 404 when product does not exist", %{token: token} do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/products/999999")

      assert json_response(conn, 404)["error"] == "not_found"
    end

    test "returns 403 when token lacks write scope", %{read_only_token: token} do
      {:ok, product} = Inventory.create_product(%{sku: "SKU-001", name: "To Delete", total_quantity: 50})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/products/#{product.id}")

      assert json_response(conn, 403)["error"] == "forbidden"
    end
  end
end
