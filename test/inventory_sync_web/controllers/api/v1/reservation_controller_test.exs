defmodule InventorySyncWeb.Api.V1.ReservationControllerTest do
  use InventorySyncWeb.ConnCase

  alias InventorySync.Accounts.{User, ApiToken}

  setup do
    # Create a user for the API token
    {:ok, user} =
      %User{}
      |> User.email_changeset(%{email: "reservation-api-user@example.com"})
      |> InventorySync.Repo.insert()

    # Create API token with inventory scopes
    attrs = %{
      name: "Reservation API Token",
      scopes: ["read:inventory", "write:inventory"],
      user_id: user.id
    }

    {raw_token, api_token_struct} = ApiToken.build_token(attrs)
    {:ok, _saved_token} = InventorySync.Repo.insert(api_token_struct)

    %{user: user, token: raw_token}
  end

  describe "authentication" do
    test "returns 401 when no authorization header is present", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/reservations")
      assert json_response(conn, 401)["error"] == "unauthorized"
    end

    test "returns 401 when authorization header is invalid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid_token")
        |> post(~p"/api/v1/reservations")

      assert json_response(conn, 401)["error"] == "unauthorized"
    end
  end

  describe "create" do
    test "returns 501 not implemented for create action", %{conn: conn, token: token} do
      reservation_params = %{
        sku: "ABC-123",
        quantity: 5,
        session_id: "checkout_session_xyz",
        ttl_seconds: 900
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/reservations", reservation: reservation_params)

      response = json_response(conn, 501)
      assert response["error"] == "not_implemented"
      assert response["message"] =~ "Phase 2"
    end

    test "returns 501 even with empty params", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/reservations")

      response = json_response(conn, 501)
      assert response["error"] == "not_implemented"
    end
  end

  describe "release" do
    test "returns 501 not implemented for release action", %{conn: conn, token: token} do
      reservation_id = Ecto.UUID.generate()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/reservations/#{reservation_id}")

      response = json_response(conn, 501)
      assert response["error"] == "not_implemented"
      assert response["message"] =~ "Phase 2"
    end

    test "returns 501 for any reservation id", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/reservations/any-id-works")

      response = json_response(conn, 501)
      assert response["error"] == "not_implemented"
    end
  end
end
