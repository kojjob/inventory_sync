defmodule InventorySyncWeb.HealthController do
  @moduledoc """
  Health check controller for container orchestration and load balancers.

  Provides endpoints for:
  - Liveness: Is the application running?
  - Readiness: Is the application ready to serve traffic?
  """
  use InventorySyncWeb, :controller

  alias InventorySync.Repo

  @doc """
  Basic health check - returns 200 if the application is running.
  Used by Docker health checks and load balancers.
  """
  def index(conn, _params) do
    health_status = %{
      status: "healthy",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      version: Application.spec(:inventory_sync, :vsn) |> to_string(),
      checks: %{
        database: check_database(),
        application: "ok"
      }
    }

    if health_status.checks.database == "ok" do
      json(conn, health_status)
    else
      conn
      |> put_status(:service_unavailable)
      |> json(%{health_status | status: "unhealthy"})
    end
  end

  @doc """
  Lightweight liveness probe - just confirms app is running.
  """
  def liveness(conn, _params) do
    json(conn, %{status: "alive"})
  end

  @doc """
  Readiness probe - confirms app is ready to accept traffic.
  Checks database connectivity.
  """
  def readiness(conn, _params) do
    case check_database() do
      "ok" ->
        json(conn, %{status: "ready"})

      error ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{status: "not_ready", reason: error})
    end
  end

  defp check_database do
    case Repo.query("SELECT 1") do
      {:ok, _result} -> "ok"
      {:error, _reason} -> "database_unavailable"
    end
  rescue
    _ -> "database_error"
  end
end
