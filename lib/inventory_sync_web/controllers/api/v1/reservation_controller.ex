defmodule InventorySyncWeb.Api.V1.ReservationController do
  @moduledoc """
  API controller for inventory reservation operations.

  Provides endpoints for:
  - Creating inventory reservations (hold stock for checkout)
  - Releasing reservations (cancel hold)

  ## Implementation Status

  This controller is a Phase 2 prerequisite stub. Full implementation
  with SKU GenServers and in-memory reservation management is planned
  for the SKU GenServers & Reservation Engine phase.

  ## Planned Features

  - Session-based reservations with configurable TTL
  - Automatic expiration of stale reservations
  - Commit reservations on successful purchase
  - Real-time available quantity calculation
  """

  use InventorySyncWeb, :controller

  action_fallback InventorySyncWeb.Api.V1.FallbackController

  @doc """
  Creates a new inventory reservation.

  ## Planned Request Body

      {
        "reservation": {
          "sku": "ABC-123",
          "quantity": 5,
          "session_id": "checkout_session_xyz",
          "ttl_seconds": 900
        }
      }

  ## Planned Response

      {
        "data": {
          "id": "uuid",
          "sku": "ABC-123",
          "quantity": 5,
          "session_id": "checkout_session_xyz",
          "status": "pending",
          "expires_at": "2024-01-15T10:45:00Z"
        }
      }

  ## Current Status

  Returns 501 Not Implemented. Full implementation pending Phase 2.
  """
  def create(conn, _params) do
    conn
    |> put_status(:not_implemented)
    |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
    |> render(:not_implemented)
  end

  @doc """
  Releases an existing inventory reservation.

  Cancels the hold on reserved inventory, making it available again.

  ## Parameters

  - `id` - The reservation UUID to release

  ## Planned Response

      {
        "data": {
          "id": "uuid",
          "status": "released",
          "released_at": "2024-01-15T10:30:00Z"
        }
      }

  ## Current Status

  Returns 501 Not Implemented. Full implementation pending Phase 2.
  """
  def release(conn, %{"id" => _id}) do
    conn
    |> put_status(:not_implemented)
    |> put_view(json: InventorySyncWeb.Api.V1.ErrorJSON)
    |> render(:not_implemented)
  end
end
