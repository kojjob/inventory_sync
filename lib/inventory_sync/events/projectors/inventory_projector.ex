defmodule InventorySync.Events.Projectors.InventoryProjector do
  @moduledoc """
  Projector for inventory-related events.

  This projector is responsible for:
  - Maintaining accurate inventory counts from events
  - Calculating available quantity (total - reserved)
  - Building audit trails for inventory changes
  - Generating inventory snapshots for fast state recovery

  ## Projection Model

  The inventory projection maintains:
  - `sku` - Product SKU
  - `quantity` - Total inventory quantity
  - `reserved` - Quantity currently reserved
  - `available` - Calculated: quantity - reserved
  - `version` - Current event version
  - `last_updated_at` - Timestamp of last change

  ## Usage

      # Project current state from events
      state = InventoryProjector.project("SKU-001")

      # Get available quantity
      available = InventoryProjector.available_quantity("SKU-001")

      # Build audit trail
      history = InventoryProjector.audit_trail("SKU-001", limit: 100)

  ## Event Subscriptions

  The projector can subscribe to real-time event streams:

      InventoryProjector.subscribe("SKU-001")
      # Will receive {:inventory_updated, state} messages
  """

  alias InventorySync.Events.{Event, EventStore}

  @doc """
  Projects the current inventory state for a SKU from its event stream.

  Returns a map with current inventory state:
  - `:sku` - The product SKU
  - `:quantity` - Total quantity
  - `:reserved` - Reserved quantity
  - `:available` - Available quantity (quantity - reserved)
  - `:version` - Current version
  - `:last_updated_at` - Timestamp of last event

  ## Example

      state = InventoryProjector.project("SKU-001")
      # => %{sku: "SKU-001", quantity: 100, reserved: 10, available: 90, version: 5}
  """
  def project(sku) do
    events = EventStore.stream(sku)

    initial_state = %{
      sku: sku,
      quantity: 0,
      reserved: 0,
      available: 0,
      version: 0,
      last_updated_at: nil,
      reservations: %{}
    }

    state =
      events
      |> Enum.reduce(initial_state, &apply_event/2)

    # Calculate available after projection
    Map.put(state, :available, state.quantity - state.reserved)
  end

  @doc """
  Gets the currently available quantity for a SKU.

  Available = Total Quantity - Reserved Quantity

  ## Example

      available = InventoryProjector.available_quantity("SKU-001")
      # => 90
  """
  def available_quantity(sku) do
    state = project(sku)
    state.available
  end

  @doc """
  Gets the reserved quantity for a SKU.

  ## Example

      reserved = InventoryProjector.reserved_quantity("SKU-001")
      # => 10
  """
  def reserved_quantity(sku) do
    state = project(sku)
    state.reserved
  end

  @doc """
  Checks if the requested quantity is available for reservation.

  ## Example

      InventoryProjector.can_reserve?("SKU-001", 5)
      # => true

      InventoryProjector.can_reserve?("SKU-001", 100)
      # => false
  """
  def can_reserve?(sku, quantity) do
    available_quantity(sku) >= quantity
  end

  @doc """
  Projects inventory state at a specific point in time.

  Useful for debugging and understanding past inventory levels.

  ## Example

      # What was the inventory yesterday?
      past_state = InventoryProjector.project_at("SKU-001", ~U[2024-01-14 12:00:00Z])
  """
  def project_at(sku, timestamp) do
    initial_state = %{
      sku: sku,
      quantity: 0,
      reserved: 0,
      available: 0,
      version: 0,
      last_updated_at: nil,
      reservations: %{}
    }

    state = EventStore.state_at(sku, timestamp)

    Map.merge(initial_state, state)
    |> Map.put(:available, Map.get(state, :quantity, 0) - Map.get(state, :reserved, 0))
  end

  @doc """
  Builds an audit trail of inventory changes for a SKU.

  Returns a list of change records, each containing:
  - `:event_type` - Type of change
  - `:quantity_before` - Quantity before change
  - `:quantity_after` - Quantity after change
  - `:reserved_before` - Reserved before change
  - `:reserved_after` - Reserved after change
  - `:occurred_at` - When the change happened
  - `:metadata` - Additional context (user, source, etc.)

  ## Options
  - `:limit` - Maximum records to return (default: 50)
  - `:since` - Only changes after this timestamp

  ## Example

      history = InventoryProjector.audit_trail("SKU-001", limit: 10)
  """
  def audit_trail(sku, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    since = Keyword.get(opts, :since, nil)

    events =
      if since do
        EventStore.stream(sku)
        |> Enum.filter(fn e -> DateTime.compare(e.occurred_at, since) != :lt end)
        |> Enum.take(limit)
      else
        EventStore.stream(sku) |> Enum.take(limit)
      end

    build_audit_trail(events)
  end

  @doc """
  Gets all active reservations for a SKU.

  Returns a list of reservation records with:
  - `:session_id` - The session holding the reservation
  - `:quantity` - Reserved quantity
  - `:created_at` - When the reservation was made

  ## Example

      reservations = InventoryProjector.active_reservations("SKU-001")
  """
  def active_reservations(sku) do
    state = project(sku)

    Map.get(state, :reservations, %{})
    |> Enum.map(fn {session_id, data} ->
      %{
        session_id: session_id,
        quantity: data.quantity,
        created_at: data.created_at
      }
    end)
  end

  @doc """
  Subscribes to inventory updates for a specific SKU.

  The calling process will receive messages of the form:
  `{:inventory_updated, %{sku: sku, state: state}}`

  ## Example

      InventoryProjector.subscribe("SKU-001")
      # Later in handle_info:
      def handle_info({:inventory_updated, %{sku: sku, state: state}}, socket) do
        # Update UI with new state
      end
  """
  def subscribe(sku) do
    Phoenix.PubSub.subscribe(InventorySync.PubSub, "events:#{sku}")
  end

  @doc """
  Unsubscribes from inventory updates for a SKU.
  """
  def unsubscribe(sku) do
    Phoenix.PubSub.unsubscribe(InventorySync.PubSub, "events:#{sku}")
  end

  @doc """
  Projects inventory for multiple SKUs efficiently.

  ## Example

      states = InventoryProjector.project_batch(["SKU-001", "SKU-002", "SKU-003"])
      # => %{"SKU-001" => %{...}, "SKU-002" => %{...}, ...}
  """
  def project_batch(skus) do
    skus
    |> Task.async_stream(&{&1, project(&1)}, max_concurrency: 10)
    |> Enum.reduce(%{}, fn {:ok, {sku, state}}, acc ->
      Map.put(acc, sku, state)
    end)
  end

  # Private functions

  defp apply_event(%Event{} = event, state) do
    new_state =
      case event.event_type do
        "inventory.quantity_updated" ->
          %{state | quantity: event.payload["new_quantity"]}

        "inventory.reserved" ->
          session_id = event.payload["session_id"]
          quantity = event.payload["quantity"]

          reservations =
            Map.put(state.reservations, session_id, %{
              quantity: quantity,
              created_at: event.occurred_at
            })

          %{state | reserved: state.reserved + quantity, reservations: reservations}

        "inventory.reservation_committed" ->
          session_id = event.payload["session_id"]
          quantity = event.payload["quantity"]
          reservations = Map.delete(state.reservations, session_id)

          %{
            state
            | quantity: state.quantity - quantity,
              reserved: max(0, state.reserved - quantity),
              reservations: reservations
          }

        "inventory.reservation_released" ->
          session_id = event.payload["session_id"]
          quantity = event.payload["quantity"]
          reservations = Map.delete(state.reservations, session_id)

          %{state | reserved: max(0, state.reserved - quantity), reservations: reservations}

        "inventory.reservation_expired" ->
          session_id = event.payload["session_id"]
          quantity = event.payload["quantity"]
          reservations = Map.delete(state.reservations, session_id)

          %{state | reserved: max(0, state.reserved - quantity), reservations: reservations}

        "product.created" ->
          %{state | quantity: event.payload["quantity"] || 0, sku: event.payload["sku"]}

        _ ->
          state
      end

    %{new_state | version: event.version, last_updated_at: event.occurred_at}
  end

  defp build_audit_trail(events) do
    {trail, _} =
      events
      |> Enum.reduce({[], %{quantity: 0, reserved: 0}}, fn event, {trail, prev} ->
        new_state = apply_audit_state(event, prev)

        record = %{
          event_type: event.event_type,
          quantity_before: prev.quantity,
          quantity_after: new_state.quantity,
          reserved_before: prev.reserved,
          reserved_after: new_state.reserved,
          change: new_state.quantity - prev.quantity,
          occurred_at: event.occurred_at,
          metadata: event.metadata
        }

        {[record | trail], new_state}
      end)

    Enum.reverse(trail)
  end

  defp apply_audit_state(event, prev) do
    case event.event_type do
      "inventory.quantity_updated" ->
        %{prev | quantity: event.payload["new_quantity"]}

      "inventory.reserved" ->
        %{prev | reserved: prev.reserved + event.payload["quantity"]}

      "inventory.reservation_committed" ->
        %{
          prev
          | quantity: prev.quantity - event.payload["quantity"],
            reserved: max(0, prev.reserved - event.payload["quantity"])
        }

      "inventory.reservation_released" ->
        %{prev | reserved: max(0, prev.reserved - event.payload["quantity"])}

      "inventory.reservation_expired" ->
        %{prev | reserved: max(0, prev.reserved - event.payload["quantity"])}

      "product.created" ->
        %{prev | quantity: event.payload["quantity"] || 0}

      _ ->
        prev
    end
  end
end
