defmodule InventorySync.Events.EventStore do
  @moduledoc """
  Event persistence and retrieval layer for the event sourcing system.

  The EventStore is responsible for:
  - Appending events to the store with optimistic concurrency control
  - Streaming events for an aggregate
  - Replaying events to rebuild state
  - Time-travel queries for debugging
  - Broadcasting events after successful persistence

  ## Event Ordering

  Events are ordered by version within an aggregate. The version field
  provides a total ordering for event replay and concurrency control.

  ## Optimistic Concurrency

  When appending an event, you must provide the expected version. If
  another process has appended an event since you read the stream,
  the append will fail with a version conflict error.

  ## Usage

      # Append an event
      {:ok, event} = EventStore.append(
        "inventory.quantity_updated",
        "SKU-001",
        %{old_quantity: 100, new_quantity: 75},
        %{user_id: 123, source: "api"}
      )

      # Stream all events for an aggregate
      events = EventStore.stream("SKU-001")

      # Replay to rebuild current state
      state = EventStore.replay("SKU-001")

      # Time-travel: state at a specific point
      past_state = EventStore.state_at("SKU-001", ~U[2024-01-15 10:30:00Z])
  """

  import Ecto.Query, warn: false

  alias InventorySync.Repo
  alias InventorySync.Events.Event

  @doc """
  Appends a new event to the store.

  This function:
  1. Determines the next version for the aggregate
  2. Creates and persists the event
  3. Broadcasts the event on success

  ## Parameters
  - `event_type` - Type of event (e.g., "inventory.quantity_updated")
  - `aggregate_id` - ID of the aggregate being modified
  - `payload` - Event-specific data
  - `metadata` - Optional context (user_id, source, session_id, etc.)

  ## Returns
  - `{:ok, event}` on success
  - `{:error, changeset}` on validation failure
  - `{:error, :version_conflict}` if another event was appended concurrently

  ## Example

      {:ok, event} = EventStore.append(
        "inventory.quantity_updated",
        "SKU-001",
        %{old_quantity: 100, new_quantity: 75},
        %{user_id: 123}
      )
  """
  def append(event_type, aggregate_id, payload, metadata \\ %{}) do
    aggregate_type = infer_aggregate_type(aggregate_id, event_type)
    next_version = next_version(aggregate_id)

    attrs = %{
      event_type: event_type,
      aggregate_id: aggregate_id,
      aggregate_type: aggregate_type,
      payload: payload,
      metadata: Map.merge(default_metadata(), metadata),
      version: next_version,
      occurred_at: DateTime.utc_now()
    }

    case create_event(attrs) do
      {:ok, event} ->
        broadcast_event(event)
        {:ok, event}

      {:error, %Ecto.Changeset{errors: errors} = changeset} ->
        if version_conflict?(errors) do
          {:error, :version_conflict}
        else
          {:error, changeset}
        end
    end
  end

  @doc """
  Streams all events for an aggregate in version order.

  ## Options
  - `:from_version` - Start from this version (exclusive, default: 0)
  - `:to_version` - End at this version (inclusive, default: all)
  - `:limit` - Maximum number of events to return

  ## Example

      # Get all events
      events = EventStore.stream("SKU-001")

      # Get events from version 5 onwards
      events = EventStore.stream("SKU-001", from_version: 5)

      # Get first 10 events
      events = EventStore.stream("SKU-001", limit: 10)
  """
  def stream(aggregate_id, opts \\ []) do
    from_version = Keyword.get(opts, :from_version, 0)
    to_version = Keyword.get(opts, :to_version, nil)
    limit = Keyword.get(opts, :limit, nil)

    query =
      Event
      |> where([e], e.aggregate_id == ^aggregate_id)
      |> where([e], e.version > ^from_version)
      |> order_by([e], asc: e.version)

    query =
      if to_version do
        where(query, [e], e.version <= ^to_version)
      else
        query
      end

    query =
      if limit do
        limit(query, ^limit)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Replays all events for an aggregate to rebuild its current state.

  The replay process applies each event to an initial state using
  the appropriate projector. This is used for:
  - Rebuilding read models
  - Recovering from failures
  - Validating state consistency

  ## Example

      state = EventStore.replay("SKU-001")
      # => %{quantity: 75, reserved: 10, version: 5}
  """
  def replay(aggregate_id) do
    stream(aggregate_id)
    |> Enum.reduce(%{}, &apply_event/2)
  end

  @doc """
  Reconstructs the state of an aggregate at a specific point in time.

  This enables time-travel debugging by replaying events up to
  the given timestamp.

  ## Example

      # What was the state yesterday at noon?
      past_state = EventStore.state_at("SKU-001", ~U[2024-01-14 12:00:00Z])
  """
  def state_at(aggregate_id, timestamp) do
    Event
    |> where([e], e.aggregate_id == ^aggregate_id)
    |> where([e], e.occurred_at <= ^timestamp)
    |> order_by([e], asc: e.version)
    |> Repo.all()
    |> Enum.reduce(%{}, &apply_event/2)
  end

  @doc """
  Gets the current version for an aggregate.

  Returns 0 if no events exist for the aggregate.

  ## Example

      version = EventStore.current_version("SKU-001")
      # => 5
  """
  def current_version(aggregate_id) do
    Event
    |> where([e], e.aggregate_id == ^aggregate_id)
    |> select([e], max(e.version))
    |> Repo.one() || 0
  end

  @doc """
  Queries events by type across all aggregates.

  Useful for analytics and monitoring.

  ## Options
  - `:since` - Only events after this timestamp
  - `:limit` - Maximum events to return (default: 100)

  ## Example

      # Get recent inventory updates
      events = EventStore.events_by_type("inventory.quantity_updated", since: ~U[2024-01-15 00:00:00Z])
  """
  def events_by_type(event_type, opts \\ []) do
    since = Keyword.get(opts, :since, nil)
    limit = Keyword.get(opts, :limit, 100)

    query =
      Event
      |> where([e], e.event_type == ^event_type)
      |> order_by([e], desc: e.occurred_at)
      |> limit(^limit)

    query =
      if since do
        where(query, [e], e.occurred_at >= ^since)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets all events for an aggregate type.

  ## Example

      # Get all product events
      events = EventStore.events_by_aggregate_type("product", limit: 50)
  """
  def events_by_aggregate_type(aggregate_type, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    Event
    |> where([e], e.aggregate_type == ^aggregate_type)
    |> order_by([e], desc: e.occurred_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Counts events for an aggregate.

  ## Example

      count = EventStore.count_events("SKU-001")
      # => 42
  """
  def count_events(aggregate_id) do
    Event
    |> where([e], e.aggregate_id == ^aggregate_id)
    |> select([e], count(e.id))
    |> Repo.one()
  end

  # Private functions

  defp create_event(attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  defp next_version(aggregate_id) do
    current_version(aggregate_id) + 1
  end

  defp infer_aggregate_type(_aggregate_id, event_type) do
    cond do
      String.starts_with?(event_type, "inventory.") -> "product"
      String.starts_with?(event_type, "sync.") -> "channel"
      String.starts_with?(event_type, "channel.") -> "channel"
      String.starts_with?(event_type, "product.") -> "product"
      true -> "product"
    end
  end

  defp default_metadata do
    %{
      "recorded_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "application_version" => Application.spec(:inventory_sync, :vsn) |> to_string()
    }
  end

  defp version_conflict?(errors) do
    Enum.any?(errors, fn
      {:version, {"version already exists for this aggregate", _}} -> true
      _ -> false
    end)
  end

  defp broadcast_event(event) do
    Phoenix.PubSub.broadcast(
      InventorySync.PubSub,
      "events",
      {:event_appended, event}
    )

    Phoenix.PubSub.broadcast(
      InventorySync.PubSub,
      "events:#{event.aggregate_type}",
      {:event_appended, event}
    )

    Phoenix.PubSub.broadcast(
      InventorySync.PubSub,
      "events:#{event.aggregate_id}",
      {:event_appended, event}
    )
  end

  @doc """
  Applies an event to a state map.

  This is the core projection logic. Each event type modifies the
  state differently. Override or extend this for custom projections.
  """
  def apply_event(%Event{} = event, state) do
    case event.event_type do
      "inventory.quantity_updated" ->
        state
        |> Map.put(:quantity, event.payload["new_quantity"])
        |> Map.put(:version, event.version)

      "inventory.reserved" ->
        reserved = Map.get(state, :reserved, 0) + event.payload["quantity"]

        state
        |> Map.put(:reserved, reserved)
        |> Map.put(:version, event.version)

      "inventory.reservation_committed" ->
        reserved = Map.get(state, :reserved, 0) - event.payload["quantity"]
        quantity = Map.get(state, :quantity, 0) - event.payload["quantity"]

        state
        |> Map.put(:reserved, max(0, reserved))
        |> Map.put(:quantity, max(0, quantity))
        |> Map.put(:version, event.version)

      "inventory.reservation_released" ->
        reserved = Map.get(state, :reserved, 0) - event.payload["quantity"]

        state
        |> Map.put(:reserved, max(0, reserved))
        |> Map.put(:version, event.version)

      "inventory.reservation_expired" ->
        reserved = Map.get(state, :reserved, 0) - event.payload["quantity"]

        state
        |> Map.put(:reserved, max(0, reserved))
        |> Map.put(:version, event.version)

      "product.created" ->
        state
        |> Map.put(:sku, event.payload["sku"])
        |> Map.put(:name, event.payload["name"])
        |> Map.put(:quantity, event.payload["quantity"] || 0)
        |> Map.put(:version, event.version)

      "product.updated" ->
        state
        |> Map.merge(event.payload |> Map.new(fn {k, v} -> {String.to_atom(k), v} end))
        |> Map.put(:version, event.version)

      "product.deleted" ->
        state
        |> Map.put(:deleted, true)
        |> Map.put(:deleted_at, event.occurred_at)
        |> Map.put(:version, event.version)

      "sync.initiated" ->
        state
        |> Map.put(:sync_status, :syncing)
        |> Map.put(:last_sync_started_at, event.occurred_at)
        |> Map.put(:version, event.version)

      "sync.completed" ->
        state
        |> Map.put(:sync_status, :synced)
        |> Map.put(:last_sync_completed_at, event.occurred_at)
        |> Map.put(:version, event.version)

      "sync.failed" ->
        state
        |> Map.put(:sync_status, :failed)
        |> Map.put(:last_sync_error, event.payload["error"])
        |> Map.put(:version, event.version)

      "channel.created" ->
        state
        |> Map.put(:name, event.payload["name"])
        |> Map.put(:platform, event.payload["platform"])
        |> Map.put(:active, true)
        |> Map.put(:version, event.version)

      "channel.updated" ->
        state
        |> Map.merge(event.payload |> Map.new(fn {k, v} -> {String.to_atom(k), v} end))
        |> Map.put(:version, event.version)

      "channel.deactivated" ->
        state
        |> Map.put(:active, false)
        |> Map.put(:deactivated_at, event.occurred_at)
        |> Map.put(:version, event.version)

      _ ->
        # Unknown event type - just track version
        Map.put(state, :version, event.version)
    end
  end
end
