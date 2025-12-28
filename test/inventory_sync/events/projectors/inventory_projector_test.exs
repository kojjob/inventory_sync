defmodule InventorySync.Events.Projectors.InventoryProjectorTest do
  use InventorySync.DataCase

  alias InventorySync.Events.EventStore
  alias InventorySync.Events.Projectors.InventoryProjector

  describe "project/1" do
    test "returns empty projection for unknown SKU" do
      state = InventoryProjector.project("UNKNOWN-SKU")

      assert state.sku == "UNKNOWN-SKU"
      assert state.quantity == 0
      assert state.reserved == 0
      assert state.available == 0
      assert state.version == 0
    end

    test "projects state from product.created event" do
      EventStore.append("product.created", "SKU-001", %{
        "sku" => "SKU-001",
        "name" => "Widget",
        "quantity" => 100
      })

      state = InventoryProjector.project("SKU-001")

      assert state.sku == "SKU-001"
      assert state.quantity == 100
      assert state.reserved == 0
      assert state.available == 100
      assert state.version == 1
    end

    test "projects state with quantity updates" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})
      EventStore.append("inventory.quantity_updated", "SKU-001", %{"new_quantity" => 75})

      state = InventoryProjector.project("SKU-001")

      assert state.quantity == 75
      assert state.available == 75
      assert state.version == 2
    end

    test "projects state with reservations" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 10,
        "session_id" => "sess-1"
      })

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 15,
        "session_id" => "sess-2"
      })

      state = InventoryProjector.project("SKU-001")

      assert state.quantity == 100
      assert state.reserved == 25
      assert state.available == 75
      assert state.version == 3
      assert map_size(state.reservations) == 2
    end

    test "projects state after reservation committed" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 20,
        "session_id" => "sess-1"
      })

      EventStore.append("inventory.reservation_committed", "SKU-001", %{
        "quantity" => 20,
        "session_id" => "sess-1"
      })

      state = InventoryProjector.project("SKU-001")

      assert state.quantity == 80
      assert state.reserved == 0
      assert state.available == 80
      assert map_size(state.reservations) == 0
    end

    test "projects state after reservation released" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 30,
        "session_id" => "sess-1"
      })

      EventStore.append("inventory.reservation_released", "SKU-001", %{
        "quantity" => 30,
        "session_id" => "sess-1"
      })

      state = InventoryProjector.project("SKU-001")

      assert state.quantity == 100
      assert state.reserved == 0
      assert state.available == 100
    end

    test "projects state after reservation expired" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 25,
        "session_id" => "sess-1"
      })

      EventStore.append("inventory.reservation_expired", "SKU-001", %{
        "quantity" => 25,
        "session_id" => "sess-1"
      })

      state = InventoryProjector.project("SKU-001")

      assert state.quantity == 100
      assert state.reserved == 0
      assert state.available == 100
    end

    test "tracks last_updated_at from events" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 50})

      state = InventoryProjector.project("SKU-001")

      assert state.last_updated_at != nil
    end
  end

  describe "available_quantity/1" do
    test "returns 0 for unknown SKU" do
      assert InventoryProjector.available_quantity("UNKNOWN") == 0
    end

    test "returns correct available quantity" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{"quantity" => 30, "session_id" => "s1"})

      assert InventoryProjector.available_quantity("SKU-001") == 70
    end
  end

  describe "reserved_quantity/1" do
    test "returns 0 for unknown SKU" do
      assert InventoryProjector.reserved_quantity("UNKNOWN") == 0
    end

    test "returns correct reserved quantity" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{"quantity" => 15, "session_id" => "s1"})

      EventStore.append("inventory.reserved", "SKU-001", %{"quantity" => 10, "session_id" => "s2"})

      assert InventoryProjector.reserved_quantity("SKU-001") == 25
    end
  end

  describe "can_reserve?/2" do
    test "returns false for unknown SKU" do
      refute InventoryProjector.can_reserve?("UNKNOWN", 1)
    end

    test "returns true when sufficient quantity available" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{"quantity" => 20, "session_id" => "s1"})

      assert InventoryProjector.can_reserve?("SKU-001", 50)
      assert InventoryProjector.can_reserve?("SKU-001", 80)
    end

    test "returns false when insufficient quantity available" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{"quantity" => 60, "session_id" => "s1"})

      refute InventoryProjector.can_reserve?("SKU-001", 50)
      refute InventoryProjector.can_reserve?("SKU-001", 41)
    end

    test "returns true for exact available quantity" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{"quantity" => 60, "session_id" => "s1"})

      assert InventoryProjector.can_reserve?("SKU-001", 40)
    end
  end

  describe "project_at/2" do
    test "returns projection at specific timestamp" do
      # Create events with controlled timestamps by inserting directly
      now = DateTime.utc_now()
      past = DateTime.add(now, -3600, :second)
      middle = DateTime.add(now, -1800, :second)

      # Insert events with specific occurred_at values
      {:ok, _} =
        %InventorySync.Events.Event{}
        |> InventorySync.Events.Event.changeset(%{
          event_type: "product.created",
          aggregate_id: "SKU-TIME",
          aggregate_type: "product",
          version: 1,
          payload: %{"sku" => "SKU-TIME", "quantity" => 100},
          occurred_at: past
        })
        |> InventorySync.Repo.insert()

      {:ok, _} =
        %InventorySync.Events.Event{}
        |> InventorySync.Events.Event.changeset(%{
          event_type: "inventory.quantity_updated",
          aggregate_id: "SKU-TIME",
          aggregate_type: "product",
          version: 2,
          payload: %{"new_quantity" => 50},
          occurred_at: middle
        })
        |> InventorySync.Repo.insert()

      {:ok, _} =
        %InventorySync.Events.Event{}
        |> InventorySync.Events.Event.changeset(%{
          event_type: "inventory.quantity_updated",
          aggregate_id: "SKU-TIME",
          aggregate_type: "product",
          version: 3,
          payload: %{"new_quantity" => 25},
          occurred_at: now
        })
        |> InventorySync.Repo.insert()

      # Query at different points in time
      state_at_past = InventoryProjector.project_at("SKU-TIME", past)
      state_at_middle = InventoryProjector.project_at("SKU-TIME", middle)
      state_at_now = InventoryProjector.project_at("SKU-TIME", now)

      assert state_at_past.quantity == 100
      assert state_at_middle.quantity == 50
      assert state_at_now.quantity == 25
    end

    test "returns empty projection for timestamp before any events" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      far_past = DateTime.add(DateTime.utc_now(), -86400, :second)
      state = InventoryProjector.project_at("SKU-001", far_past)

      assert state.available == 0
    end
  end

  describe "audit_trail/2" do
    setup do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})
      EventStore.append("inventory.quantity_updated", "SKU-001", %{"new_quantity" => 80})

      EventStore.append("inventory.reserved", "SKU-001", %{"quantity" => 10, "session_id" => "s1"})

      EventStore.append("inventory.reservation_committed", "SKU-001", %{
        "quantity" => 10,
        "session_id" => "s1"
      })

      :ok
    end

    test "returns audit trail with quantity changes" do
      trail = InventoryProjector.audit_trail("SKU-001")

      assert length(trail) == 4

      [first, second, third, fourth] = trail

      # First event: product created with 100
      assert first.event_type == "product.created"
      assert first.quantity_before == 0
      assert first.quantity_after == 100

      # Second event: quantity updated to 80
      assert second.event_type == "inventory.quantity_updated"
      assert second.quantity_before == 100
      assert second.quantity_after == 80

      # Third event: reserved 10
      assert third.event_type == "inventory.reserved"
      assert third.reserved_before == 0
      assert third.reserved_after == 10

      # Fourth event: committed reservation (quantity decreases, reserved resets)
      assert fourth.event_type == "inventory.reservation_committed"
      assert fourth.quantity_before == 80
      assert fourth.quantity_after == 70
      assert fourth.reserved_before == 10
      assert fourth.reserved_after == 0
    end

    test "respects limit option" do
      trail = InventoryProjector.audit_trail("SKU-001", limit: 2)
      assert length(trail) == 2
    end

    test "returns empty trail for unknown SKU" do
      trail = InventoryProjector.audit_trail("UNKNOWN")
      assert trail == []
    end

    test "filters by since timestamp" do
      now = DateTime.utc_now()
      since = DateTime.add(now, -1, :second)

      trail = InventoryProjector.audit_trail("SKU-001", since: since)

      # All events were created very recently, so all should match
      assert Enum.all?(trail, fn record ->
               DateTime.compare(record.occurred_at, since) != :lt
             end)
    end
  end

  describe "active_reservations/1" do
    test "returns empty list when no reservations" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      reservations = InventoryProjector.active_reservations("SKU-001")
      assert reservations == []
    end

    test "returns active reservations" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 10,
        "session_id" => "sess-1"
      })

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 20,
        "session_id" => "sess-2"
      })

      reservations = InventoryProjector.active_reservations("SKU-001")

      assert length(reservations) == 2

      session_ids = Enum.map(reservations, & &1.session_id)
      assert "sess-1" in session_ids
      assert "sess-2" in session_ids

      sess1_res = Enum.find(reservations, &(&1.session_id == "sess-1"))
      assert sess1_res.quantity == 10
      assert sess1_res.created_at != nil
    end

    test "excludes committed reservations" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 10,
        "session_id" => "sess-1"
      })

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 20,
        "session_id" => "sess-2"
      })

      EventStore.append("inventory.reservation_committed", "SKU-001", %{
        "quantity" => 10,
        "session_id" => "sess-1"
      })

      reservations = InventoryProjector.active_reservations("SKU-001")

      assert length(reservations) == 1
      assert hd(reservations).session_id == "sess-2"
    end

    test "excludes released reservations" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 10,
        "session_id" => "sess-1"
      })

      EventStore.append("inventory.reservation_released", "SKU-001", %{
        "quantity" => 10,
        "session_id" => "sess-1"
      })

      reservations = InventoryProjector.active_reservations("SKU-001")
      assert reservations == []
    end

    test "excludes expired reservations" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 10,
        "session_id" => "sess-1"
      })

      EventStore.append("inventory.reservation_expired", "SKU-001", %{
        "quantity" => 10,
        "session_id" => "sess-1"
      })

      reservations = InventoryProjector.active_reservations("SKU-001")
      assert reservations == []
    end
  end

  describe "subscribe/1 and unsubscribe/1" do
    test "subscribes to PubSub for SKU events" do
      InventoryProjector.subscribe("SKU-001")

      # Append an event which triggers broadcast
      {:ok, event} =
        EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 50})

      # Should receive the event
      assert_receive {:event_appended, ^event}
    end

    test "unsubscribes from PubSub for SKU events" do
      InventoryProjector.subscribe("SKU-001")
      InventoryProjector.unsubscribe("SKU-001")

      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 50})

      # Should NOT receive the event after unsubscribe
      refute_receive {:event_appended, _}, 100
    end
  end

  describe "project_batch/1" do
    test "returns empty map for empty list" do
      result = InventoryProjector.project_batch([])
      assert result == %{}
    end

    test "projects multiple SKUs concurrently" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})
      EventStore.append("product.created", "SKU-002", %{"sku" => "SKU-002", "quantity" => 200})
      EventStore.append("product.created", "SKU-003", %{"sku" => "SKU-003", "quantity" => 300})

      EventStore.append("inventory.reserved", "SKU-001", %{"quantity" => 10, "session_id" => "s1"})

      EventStore.append("inventory.reserved", "SKU-002", %{"quantity" => 50, "session_id" => "s2"})

      result = InventoryProjector.project_batch(["SKU-001", "SKU-002", "SKU-003"])

      assert map_size(result) == 3

      assert result["SKU-001"].quantity == 100
      assert result["SKU-001"].reserved == 10
      assert result["SKU-001"].available == 90

      assert result["SKU-002"].quantity == 200
      assert result["SKU-002"].reserved == 50
      assert result["SKU-002"].available == 150

      assert result["SKU-003"].quantity == 300
      assert result["SKU-003"].reserved == 0
      assert result["SKU-003"].available == 300
    end

    test "includes unknown SKUs with empty projections" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      result = InventoryProjector.project_batch(["SKU-001", "UNKNOWN-SKU"])

      assert map_size(result) == 2
      assert result["SKU-001"].quantity == 100
      assert result["UNKNOWN-SKU"].quantity == 0
    end
  end
end
