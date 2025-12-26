defmodule InventorySyncWeb.Api.V1.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use InventorySyncWeb, :controller

  @doc """
  Handles common error responses from controller actions.

  ## Supported patterns

  - `{:error, %Ecto.Changeset{}}` - Returns 422 with validation errors
  - `{:error, :not_found}` - Returns 404 not found
  - `{:error, :forbidden}` - Returns 403 forbidden
  """
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
    |> render(:changeset_errors, changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
    |> render(:not_found)
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
    |> render(:forbidden)
  end
end
