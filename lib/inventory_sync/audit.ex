defmodule InventorySync.Audit do
  @moduledoc """
  The Audit context.
  Provides functionality for tracking and querying audit logs.
  """

  import Ecto.Query, warn: false
  alias InventorySync.Repo

  alias InventorySync.Audit.AuditLog
  alias InventorySync.Accounts.User
  alias InventorySync.Inventory.{Channel, Product, TeamMember}

  @doc """
  Returns the list of audit_logs.

  ## Options

    * `:resource_type` - Filter by resource type (e.g., "channel", "product")
    * `:user_id` - Filter by user ID
    * `:action` - Filter by action type
    * `:limit` - Limit the number of results

  ## Examples

      iex> list_audit_logs()
      [%AuditLog{}, ...]

      iex> list_audit_logs(resource_type: "channel", limit: 10)
      [%AuditLog{}, ...]

  """
  def list_audit_logs(opts \\ []) do
    AuditLog
    |> apply_filters(opts)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
  end

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:resource_type, type}, q -> where(q, [a], a.resource_type == ^type)
      {:user_id, user_id}, q -> where(q, [a], a.user_id == ^user_id)
      {:action, action}, q -> where(q, [a], a.action == ^action)
      {:limit, limit}, q -> limit(q, ^limit)
      _, q -> q
    end)
  end

  @doc """
  Returns the list of audit_logs for a specific resource.

  ## Examples

      iex> list_audit_logs_for_resource("channel", 123)
      [%AuditLog{}, ...]

  """
  def list_audit_logs_for_resource(resource_type, resource_id) do
    AuditLog
    |> where([a], a.resource_type == ^resource_type and a.resource_id == ^resource_id)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns recent audit_logs with user preloaded.

  ## Examples

      iex> list_recent_audit_logs(10)
      [%AuditLog{user: %User{}}, ...]

  """
  def list_recent_audit_logs(limit \\ 10) do
    AuditLog
    |> order_by([a], desc: a.inserted_at)
    |> limit(^limit)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Gets a single audit_log.

  Raises `Ecto.NoResultsError` if the Audit log does not exist.

  ## Examples

      iex> get_audit_log!(123)
      %AuditLog{}

      iex> get_audit_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_audit_log!(id), do: Repo.get!(AuditLog, id)

  @doc """
  Creates an audit_log.

  ## Examples

      iex> create_audit_log(%{field: value})
      {:ok, %AuditLog{}}

      iex> create_audit_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_audit_log(attrs \\ %{}) do
    %AuditLog{}
    |> AuditLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Logs an action for a resource.

  Automatically determines the resource_type from the struct.

  ## Examples

      iex> log_action(user, "created", channel, %{"name" => %{"from" => nil, "to" => "My Channel"}})
      {:ok, %AuditLog{}}

  """
  def log_action(%User{} = user, action, resource, changes, metadata \\ %{}) do
    {resource_type, resource_id} = extract_resource_info(resource)

    create_audit_log(%{
      action: action,
      resource_type: resource_type,
      resource_id: resource_id,
      changes: changes,
      metadata: metadata,
      user_id: user.id
    })
  end

  defp extract_resource_info(%Channel{id: id}), do: {"channel", id}
  defp extract_resource_info(%Product{id: id}), do: {"product", id}
  defp extract_resource_info(%TeamMember{id: id}), do: {"team_member", id}

  defp extract_resource_info(%{__struct__: module, id: id}) do
    type = module |> Module.split() |> List.last() |> Macro.underscore()
    {type, id}
  end

  @doc """
  Returns the count of audit_logs created today.

  ## Examples

      iex> count_audit_logs_today()
      42

  """
  def count_audit_logs_today do
    today_start = DateTime.utc_now() |> DateTime.to_date() |> DateTime.new!(~T[00:00:00])

    Repo.one(
      from a in AuditLog,
        where: a.inserted_at >= ^today_start,
        select: count(a.id)
    )
  end

  @doc """
  Calculates the changes between old and new values for audit logging.

  ## Examples

      iex> calculate_changes(%{name: "old"}, %{name: "new"})
      %{"name" => %{"from" => "old", "to" => "new"}}

  """
  def calculate_changes(old_attrs, new_attrs) when is_map(old_attrs) and is_map(new_attrs) do
    new_attrs
    |> Enum.reduce(%{}, fn {key, new_value}, acc ->
      old_value = Map.get(old_attrs, key)

      if old_value != new_value do
        Map.put(acc, to_string(key), %{"from" => old_value, "to" => new_value})
      else
        acc
      end
    end)
  end

  def calculate_changes(nil, new_attrs) when is_map(new_attrs) do
    new_attrs
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, to_string(key), %{"from" => nil, "to" => value})
    end)
  end
end
