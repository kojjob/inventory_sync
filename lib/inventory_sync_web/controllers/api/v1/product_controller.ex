defmodule InventorySyncWeb.Api.V1.ProductController do
  use InventorySyncWeb, :controller

  alias InventorySync.Inventory

  action_fallback InventorySyncWeb.Api.V1.FallbackController

  # Require write scope for create, update, delete actions
  plug :require_write_scope when action in [:create, :update, :delete]

  def index(conn, _params) do
    products = Inventory.list_products()
    render(conn, :index, products: products)
  end

  def show(conn, %{"id" => id}) do
    product = Inventory.get_product!(id)
    render(conn, :show, product: product)
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
      |> render(:not_found)
  end

  def create(conn, %{"product" => product_params}) do
    case Inventory.create_product(product_params) do
      {:ok, product} ->
        conn
        |> put_status(:created)
        |> render(:show, product: product)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
        |> render(:changeset_errors, changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "product" => product_params}) do
    product = Inventory.get_product!(id)

    case Inventory.update_product(product, product_params) do
      {:ok, product} ->
        render(conn, :show, product: product)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
        |> render(:changeset_errors, changeset: changeset)
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
      |> render(:not_found)
  end

  def delete(conn, %{"id" => id}) do
    product = Inventory.get_product!(id)

    case Inventory.delete_product(product) do
      {:ok, _product} ->
        send_resp(conn, :no_content, "")

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
        |> render(:error, message: "Could not delete product")
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
      |> render(:not_found)
  end

  # Private function to check write scope
  defp require_write_scope(conn, _opts) do
    api_token = conn.assigns[:api_token]

    if api_token && InventorySync.Accounts.ApiToken.has_scope?(api_token, "write:products") do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
      |> render(:forbidden)
      |> halt()
    end
  end
end
