defmodule InventorySync.Release do
  @moduledoc """
  Release tasks for running database migrations and other
  setup commands in production environments.

  Usage:
    bin/inventory_sync eval "InventorySync.Release.migrate()"
    bin/inventory_sync eval "InventorySync.Release.rollback(InventorySync.Repo, 20240101000000)"
  """

  @app :inventory_sync

  @doc """
  Runs all pending migrations.
  """
  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  @doc """
  Rolls back a specific migration by version.
  """
  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Creates the database if it doesn't exist.
  """
  def create do
    load_app()

    for repo <- repos() do
      repo.__adapter__().storage_up(repo.config())
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
