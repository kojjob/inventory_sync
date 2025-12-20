defmodule InventorySyncWeb.HealthControllerTest do
  use InventorySyncWeb.ConnCase

  describe "GET /health" do
    test "returns healthy status with all checks passing", %{conn: conn} do
      conn = get(conn, ~p"/health")
      response = json_response(conn, 200)

      assert response["status"] == "healthy"
      assert response["timestamp"]
      assert response["version"]
      assert response["checks"]["database"] == "ok"
      assert response["checks"]["application"] == "ok"
    end
  end

  describe "GET /health/live" do
    test "returns alive status for liveness probe", %{conn: conn} do
      conn = get(conn, ~p"/health/live")
      response = json_response(conn, 200)

      assert response["status"] == "alive"
    end
  end

  describe "GET /health/ready" do
    test "returns ready status when database is available", %{conn: conn} do
      conn = get(conn, ~p"/health/ready")
      response = json_response(conn, 200)

      assert response["status"] == "ready"
    end
  end
end
