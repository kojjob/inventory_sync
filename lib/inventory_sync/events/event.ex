defmodule InventorySync.Events.Event do
  @moduledoc """
  Schema for inventory events in the event sourcing system.

  Events are immutable records of state changes. Each event represents
  a single atomic change to an aggregate (product, reservation, channel).

  ## Event Types

  Inventory events:
  - `inventory.quantity_updated` - Stock level changed
  - `inventory.reserved` - Quantity reserved for session
  - `inventory.reservation_committed` - Reservation converted to sale
  - `inventory.reservation_expired` - Reservation TTL exceeded
  - `inventory.reservation_released` - Reservation manually released

  Sync events:
  - `sync.initiated` - Channel sync started
  - `sync.completed` - Channel sync finished
  - `sync.failed` - Channel sync error

  Channel events:
  - `channel.created` - New sales channel added
  - `channel.updated` - Channel configuration changed
  - `channel.deactivated` - Channel disabled

  Product events:
  - `product.created` - New product added
  - `product.updated` - Product information changed
  - `product.deleted` - Product removed

  ## Aggregate Types

  - `product` - Inventory product aggregate
  - `reservation` - Inventory reservation aggregate
  - `channel` - Sales channel aggregate
  - `inventory_item` - Channel-specific inventory allocation

  ## Usage

      # Create an event
      Event.changeset(%Event{}, %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        payload: %{old_quantity: 100, new_quantity: 75, reason: "sale"},
        metadata: %{user_id: 123, source: "api"}
      })

  ## Optimistic Concurrency

  The `version` field enforces optimistic concurrency control. Each event
  for an aggregate must have a unique, incrementing version number. This
  prevents race conditions when multiple processes try to update the same
  aggregate simultaneously.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @event_types ~w(
    inventory.quantity_updated
    inventory.reserved
    inventory.reservation_committed
    inventory.reservation_expired
    inventory.reservation_released
    sync.initiated
    sync.completed
    sync.failed
    channel.created
    channel.updated
    channel.deactivated
    product.created
    product.updated
    product.deleted
  )

  @aggregate_types ~w(product reservation channel inventory_item)

  schema "inventory_events" do
    field :event_type, :string
    field :aggregate_id, :string
    field :aggregate_type, :string
    field :payload, :map, default: %{}
    field :metadata, :map, default: %{}
    field :version, :integer
    field :occurred_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Returns list of valid event types.
  """
  def event_types, do: @event_types

  @doc """
  Returns list of valid aggregate types.
  """
  def aggregate_types, do: @aggregate_types

  @doc """
  Creates a changeset for an event.

  ## Required Fields
  - `event_type` - Type of the event (e.g., "inventory.quantity_updated")
  - `aggregate_id` - ID of the aggregate (e.g., SKU or entity UUID)
  - `aggregate_type` - Type of aggregate ("product", "reservation", "channel", "inventory_item")
  - `version` - Sequence number for this aggregate

  ## Optional Fields
  - `payload` - Event-specific data (defaults to empty map)
  - `metadata` - Additional context like user_id, source (defaults to empty map)
  - `occurred_at` - When the event occurred (defaults to current time)
  """
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :event_type,
      :aggregate_id,
      :aggregate_type,
      :payload,
      :metadata,
      :version,
      :occurred_at
    ])
    |> validate_required([:event_type, :aggregate_id, :aggregate_type, :version])
    |> validate_inclusion(:event_type, @event_types, message: "must be a valid event type")
    |> validate_inclusion(:aggregate_type, @aggregate_types,
      message: "must be a valid aggregate type"
    )
    |> validate_number(:version, greater_than: 0)
    |> put_occurred_at()
    |> unique_constraint(:version,
      name: :inventory_events_aggregate_version_unique,
      message: "version already exists for this aggregate"
    )
  end

  defp put_occurred_at(changeset) do
    case get_field(changeset, :occurred_at) do
      nil -> put_change(changeset, :occurred_at, DateTime.utc_now())
      _ -> changeset
    end
  end

  @doc """
  Builds an event struct with defaults applied.

  Useful for creating events programmatically before persisting.

  ## Example

      Event.build(%{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 1,
        payload: %{quantity: 100}
      })
  """
  def build(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:build)
  end
end
