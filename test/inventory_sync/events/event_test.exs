defmodule InventorySync.Events.EventTest do
  use InventorySync.DataCase

  alias InventorySync.Events.Event

  describe "event_types/0" do
    test "returns list of valid event types" do
      types = Event.event_types()

      assert "inventory.quantity_updated" in types
      assert "inventory.reserved" in types
      assert "inventory.reservation_committed" in types
      assert "inventory.reservation_expired" in types
      assert "inventory.reservation_released" in types
      assert "sync.initiated" in types
      assert "sync.completed" in types
      assert "sync.failed" in types
      assert "product.created" in types
      assert "product.updated" in types
      assert "product.deleted" in types
      assert "channel.created" in types
      assert "channel.updated" in types
      assert "channel.deactivated" in types
    end
  end

  describe "aggregate_types/0" do
    test "returns list of valid aggregate types" do
      types = Event.aggregate_types()

      assert "product" in types
      assert "reservation" in types
      assert "channel" in types
      assert "inventory_item" in types
    end
  end

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 1,
        payload: %{"old_quantity" => 100, "new_quantity" => 75},
        metadata: %{"user_id" => 123}
      }

      changeset = Event.changeset(%Event{}, attrs)

      assert changeset.valid?
    end

    test "valid changeset with minimal required fields" do
      attrs = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 1
      }

      changeset = Event.changeset(%Event{}, attrs)

      assert changeset.valid?
    end

    test "invalid changeset missing event_type" do
      attrs = %{
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 1
      }

      changeset = Event.changeset(%Event{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).event_type
    end

    test "invalid changeset missing aggregate_id" do
      attrs = %{
        event_type: "inventory.quantity_updated",
        aggregate_type: "product",
        version: 1
      }

      changeset = Event.changeset(%Event{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).aggregate_id
    end

    test "invalid changeset missing aggregate_type" do
      attrs = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        version: 1
      }

      changeset = Event.changeset(%Event{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).aggregate_type
    end

    test "invalid changeset missing version" do
      attrs = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "product"
      }

      changeset = Event.changeset(%Event{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).version
    end

    test "invalid changeset with invalid event_type" do
      attrs = %{
        event_type: "invalid.event.type",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 1
      }

      changeset = Event.changeset(%Event{}, attrs)

      refute changeset.valid?
      assert "must be a valid event type" in errors_on(changeset).event_type
    end

    test "invalid changeset with invalid aggregate_type" do
      attrs = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "invalid_type",
        version: 1
      }

      changeset = Event.changeset(%Event{}, attrs)

      refute changeset.valid?
      assert "must be a valid aggregate type" in errors_on(changeset).aggregate_type
    end

    test "invalid changeset with version less than or equal to 0" do
      attrs = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 0
      }

      changeset = Event.changeset(%Event{}, attrs)

      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).version
    end

    test "sets occurred_at when not provided" do
      attrs = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 1
      }

      changeset = Event.changeset(%Event{}, attrs)
      occurred_at = Ecto.Changeset.get_field(changeset, :occurred_at)

      assert occurred_at != nil
      assert DateTime.diff(DateTime.utc_now(), occurred_at) < 2
    end

    test "preserves occurred_at when provided" do
      custom_time = ~U[2024-01-15 10:30:00.000000Z]

      attrs = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 1,
        occurred_at: custom_time
      }

      changeset = Event.changeset(%Event{}, attrs)
      occurred_at = Ecto.Changeset.get_field(changeset, :occurred_at)

      assert occurred_at == custom_time
    end

    test "defaults payload to empty map" do
      attrs = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 1
      }

      changeset = Event.changeset(%Event{}, attrs)
      payload = Ecto.Changeset.get_field(changeset, :payload)

      assert payload == %{}
    end

    test "defaults metadata to empty map" do
      attrs = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 1
      }

      changeset = Event.changeset(%Event{}, attrs)
      metadata = Ecto.Changeset.get_field(changeset, :metadata)

      assert metadata == %{}
    end
  end

  describe "build/1" do
    test "returns {:ok, event} with valid attributes" do
      attrs = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 1,
        payload: %{"quantity" => 100}
      }

      assert {:ok, event} = Event.build(attrs)
      assert event.event_type == "inventory.quantity_updated"
      assert event.aggregate_id == "SKU-001"
      assert event.aggregate_type == "product"
      assert event.version == 1
      assert event.payload == %{"quantity" => 100}
    end

    test "returns {:error, changeset} with invalid attributes" do
      attrs = %{
        event_type: "invalid.type",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 1
      }

      assert {:error, changeset} = Event.build(attrs)
      refute changeset.valid?
    end
  end

  describe "database persistence" do
    test "inserts event with valid data" do
      attrs = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 1,
        payload: %{"old_quantity" => 100, "new_quantity" => 75},
        metadata: %{"user_id" => 123}
      }

      assert {:ok, event} =
               %Event{}
               |> Event.changeset(attrs)
               |> Repo.insert()

      assert event.id != nil
      assert event.event_type == "inventory.quantity_updated"
      assert event.aggregate_id == "SKU-001"
      assert event.aggregate_type == "product"
      assert event.version == 1
      assert event.payload == %{"old_quantity" => 100, "new_quantity" => 75}
      assert event.metadata == %{"user_id" => 123}
      assert event.occurred_at != nil
    end

    test "enforces unique constraint on aggregate_id + version" do
      attrs = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 1
      }

      # First insert should succeed
      assert {:ok, _event1} =
               %Event{}
               |> Event.changeset(attrs)
               |> Repo.insert()

      # Second insert with same aggregate_id and version should fail
      assert {:error, changeset} =
               %Event{}
               |> Event.changeset(attrs)
               |> Repo.insert()

      assert "version already exists for this aggregate" in errors_on(changeset).version
    end

    test "allows same version for different aggregates" do
      attrs1 = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-001",
        aggregate_type: "product",
        version: 1
      }

      attrs2 = %{
        event_type: "inventory.quantity_updated",
        aggregate_id: "SKU-002",
        aggregate_type: "product",
        version: 1
      }

      assert {:ok, _event1} =
               %Event{}
               |> Event.changeset(attrs1)
               |> Repo.insert()

      assert {:ok, _event2} =
               %Event{}
               |> Event.changeset(attrs2)
               |> Repo.insert()
    end
  end
end
