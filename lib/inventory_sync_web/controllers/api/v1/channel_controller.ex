defmodule InventorySyncWeb.Api.V1.ChannelController do
  use InventorySyncWeb, :controller

  alias InventorySync.Inventory

  action_fallback InventorySyncWeb.Api.V1.FallbackController

  # Require write scope for create, update, delete actions
  plug :require_write_scope when action in [:create, :update, :delete]

  def index(conn, _params) do
    channels = Inventory.list_channels()
    render(conn, :index, channels: channels)
  end

  def show(conn, %{"id" => id}) do
    channel = Inventory.get_channel!(id)
    render(conn, :show, channel: channel)
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
      |> render(:not_found)
  end

  def create(conn, %{"channel" => channel_params}) do
    case Inventory.create_channel(channel_params) do
      {:ok, channel} ->
        conn
        |> put_status(:created)
        |> render(:show, channel: channel)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
        |> render(:changeset_errors, changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "channel" => channel_params}) do
    channel = Inventory.get_channel!(id)

    case Inventory.update_channel(channel, channel_params) do
      {:ok, channel} ->
        render(conn, :show, channel: channel)

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
    channel = Inventory.get_channel!(id)

    case Inventory.delete_channel(channel) do
      {:ok, _channel} ->
        send_resp(conn, :no_content, "")

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
        |> render(:error, message: "Could not delete channel")
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

    if api_token && InventorySync.Accounts.ApiToken.has_scope?(api_token, "write:channels") do
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
