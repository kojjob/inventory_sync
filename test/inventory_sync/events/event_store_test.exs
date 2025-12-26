defmodule InventorySync.Events.EventStoreTest do
  use InventorySync.DataCase

  alias InventorySync.Events.{Event, EventStore}

  describe "append/4" do
    test "appends event with auto-generated version" do
      assert {:ok, event} =
               EventStore.append(
                 "inventory.quantity_updated",
                 "SKU-001",
                 %{"old_quantity" => 100, "new_quantity" => 75}
               )

      assert event.event_type == "inventory.quantity_updated"
      assert event.aggregate_id == "SKU-001"
      assert event.aggregate_type == "product"
      assert event.version == 1
      assert event.payload == %{"old_quantity" => 100, "new_quantity" => 75}
      assert event.occurred_at != nil
    end

    test "appends event with metadata" do
      metadata = %{"user_id" => 123, "source" => "api"}

      assert {:ok, event} =
               EventStore.append(
                 "inventory.quantity_updated",
                 "SKU-001",
                 %{"quantity" => 50},
                 metadata
               )

      assert event.metadata["user_id"] == 123
      assert event.metadata["source"] == "api"
      # Default metadata fields are merged
      assert event.metadata["recorded_at"] != nil
      assert event.metadata["application_version"] != nil
    end

    test "increments version for subsequent events on same aggregate" do
      {:ok, event1} =
        EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "name" => "Widget"})

      {:ok, event2} =
        EventStore.append("inventory.quantity_updated", "SKU-001", %{"new_quantity" => 100})

      {:ok, event3} =
        EventStore.append("inventory.reserved", "SKU-001", %{
          "quantity" => 10,
          "session_id" => "sess-1"
        })

      assert event1.version == 1
      assert event2.version == 2
      assert event3.version == 3
    end

    test "different aggregates have independent version sequences" do
      {:ok, event1} = EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001"})
      {:ok, event2} = EventStore.append("product.created", "SKU-002", %{"sku" => "SKU-002"})

      {:ok, event3} =
        EventStore.append("inventory.quantity_updated", "SKU-001", %{"new_quantity" => 50})

      assert event1.version == 1
      assert event2.version == 1
      assert event3.version == 2
    end

    test "infers aggregate_type from event_type" do
      {:ok, inventory_event} =
        EventStore.append("inventory.quantity_updated", "SKU-001", %{})

      {:ok, sync_event} =
        EventStore.append("sync.initiated", "CHANNEL-001", %{})

      {:ok, channel_event} =
        EventStore.append("channel.created", "CHANNEL-002", %{"name" => "Test"})

      {:ok, product_event} =
        EventStore.append("product.created", "SKU-002", %{})

      assert inventory_event.aggregate_type == "product"
      assert sync_event.aggregate_type == "channel"
      assert channel_event.aggregate_type == "channel"
      assert product_event.aggregate_type == "product"
    end

    test "returns error for invalid event_type" do
      assert {:error, changeset} =
               EventStore.append("invalid.event.type", "SKU-001", %{})

      refute changeset.valid?
      assert "must be a valid event type" in errors_on(changeset).event_type
    end

    test "broadcasts event on successful append" do
      Phoenix.PubSub.subscribe(InventorySync.PubSub, "events")
      Phoenix.PubSub.subscribe(InventorySync.PubSub, "events:product")
      Phoenix.PubSub.subscribe(InventorySync.PubSub, "events:SKU-001")

      {:ok, event} =
        EventStore.append("inventory.quantity_updated", "SKU-001", %{"new_quantity" => 50})

      assert_receive {:event_appended, ^event}
      assert_receive {:event_appended, ^event}
      assert_receive {:event_appended, ^event}
    end
  end

  describe "stream/2" do
    setup do
      # Create a sequence of events for testing
      {:ok, _} =
        EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      {:ok, _} =
        EventStore.append("inventory.reserved", "SKU-001", %{
          "quantity" => 10,
          "session_id" => "sess-1"
        })

      {:ok, _} =
        EventStore.append("inventory.quantity_updated", "SKU-001", %{"new_quantity" => 90})

      {:ok, _} =
        EventStore.append("inventory.reservation_committed", "SKU-001", %{
          "quantity" => 10,
          "session_id" => "sess-1"
        })

      :ok
    end

    test "streams all events for an aggregate in version order" do
      events = EventStore.stream("SKU-001")

      assert length(events) == 4
      assert Enum.map(events, & &1.version) == [1, 2, 3, 4]

      assert Enum.map(events, & &1.event_type) == [
               "product.created",
               "inventory.reserved",
               "inventory.quantity_updated",
               "inventory.reservation_committed"
             ]
    end

    test "returns empty list for unknown aggregate" do
      events = EventStore.stream("UNKNOWN-SKU")
      assert events == []
    end

    test "filters events from specific version" do
      events = EventStore.stream("SKU-001", from_version: 2)

      assert length(events) == 2
      assert Enum.map(events, & &1.version) == [3, 4]
    end

    test "filters events up to specific version" do
      events = EventStore.stream("SKU-001", to_version: 2)

      assert length(events) == 2
      assert Enum.map(events, & &1.version) == [1, 2]
    end

    test "filters events in version range" do
      events = EventStore.stream("SKU-001", from_version: 1, to_version: 3)

      assert length(events) == 2
      assert Enum.map(events, & &1.version) == [2, 3]
    end

    test "limits number of events returned" do
      events = EventStore.stream("SKU-001", limit: 2)

      assert length(events) == 2
      assert Enum.map(events, & &1.version) == [1, 2]
    end
  end

  describe "replay/1" do
    test "rebuilds state from product lifecycle events" do
      EventStore.append("product.created", "SKU-001", %{
        "sku" => "SKU-001",
        "name" => "Widget",
        "quantity" => 100
      })

      EventStore.append("inventory.quantity_updated", "SKU-001", %{"new_quantity" => 75})

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 10,
        "session_id" => "sess-1"
      })

      state = EventStore.replay("SKU-001")

      assert state.sku == "SKU-001"
      assert state.name == "Widget"
      assert state.quantity == 75
      assert state.reserved == 10
      assert state.version == 3
    end

    test "rebuilds state after reservation commit" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 20,
        "session_id" => "sess-1"
      })

      EventStore.append("inventory.reservation_committed", "SKU-001", %{
        "quantity" => 20,
        "session_id" => "sess-1"
      })

      state = EventStore.replay("SKU-001")

      assert state.quantity == 80
      assert state.reserved == 0
      assert state.version == 3
    end

    test "rebuilds state after reservation release" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 20,
        "session_id" => "sess-1"
      })

      EventStore.append("inventory.reservation_released", "SKU-001", %{
        "quantity" => 20,
        "session_id" => "sess-1"
      })

      state = EventStore.replay("SKU-001")

      assert state.quantity == 100
      assert state.reserved == 0
      assert state.version == 3
    end

    test "rebuilds state after reservation expiry" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001", "quantity" => 100})

      EventStore.append("inventory.reserved", "SKU-001", %{
        "quantity" => 15,
        "session_id" => "sess-1"
      })

      EventStore.append("inventory.reservation_expired", "SKU-001", %{
        "quantity" => 15,
        "session_id" => "sess-1"
      })

      state = EventStore.replay("SKU-001")

      assert state.quantity == 100
      assert state.reserved == 0
    end

    test "rebuilds channel state" do
      EventStore.append("channel.created", "CH-001", %{
        "name" => "Shopify Store",
        "platform" => "shopify"
      })

      EventStore.append("channel.updated", "CH-001", %{"name" => "Main Shopify Store"})

      state = EventStore.replay("CH-001")

      assert state.name == "Main Shopify Store"
      assert state.platform == "shopify"
      assert state.active == true
    end

    test "rebuilds channel deactivation state" do
      EventStore.append("channel.created", "CH-001", %{
        "name" => "Old Store",
        "platform" => "etsy"
      })

      EventStore.append("channel.deactivated", "CH-001", %{})

      state = EventStore.replay("CH-001")

      assert state.active == false
      assert state.deactivated_at != nil
    end

    test "rebuilds sync state" do
      EventStore.append("sync.initiated", "CH-001", %{})
      EventStore.append("sync.completed", "CH-001", %{})

      state = EventStore.replay("CH-001")

      assert state.sync_status == :synced
      assert state.last_sync_completed_at != nil
    end

    test "rebuilds sync failure state" do
      EventStore.append("sync.initiated", "CH-001", %{})
      EventStore.append("sync.failed", "CH-001", %{"error" => "Connection timeout"})

      state = EventStore.replay("CH-001")

      assert state.sync_status == :failed
      assert state.last_sync_error == "Connection timeout"
    end

    test "handles product deletion" do
      EventStore.append("product.created", "SKU-001", %{"sku" => "SKU-001"})
      EventStore.append("product.deleted", "SKU-001", %{})

      state = EventStore.replay("SKU-001")

      assert state.deleted == true
      assert state.deleted_at != nil
    end

    test "returns empty map for unknown aggregate" do
      state = EventStore.replay("UNKNOWN")
      assert state == %{}
    end
  end

  describe "state_at/2" do
    test "reconstructs state at specific point in time" do
      # Create events with controlled timestamps
      now = DateTime.utc_now()
      past = DateTime.add(now, -3600, :second)
      middle = DateTime.add(now, -1800, :second)

      # We need to insert events directly to control occurred_at
      {:ok, _} =
        %Event{}
        |> Event.changeset(%{
          event_type: "product.created",
          aggregate_id: "SKU-TIME",
          aggregate_type: "product",
          version: 1,
          payload: %{"quantity" => 100},
          occurred_at: past
        })
        |> Repo.insert()

      {:ok, _} =
        %Event{}
        |> Event.changeset(%{
          event_type: "inventory.quantity_updated",
          aggregate_id: "SKU-TIME",
          aggregate_type: "product",
          version: 2,
          payload: %{"new_quantity" => 50},
          occurred_at: middle
        })
        |> Repo.insert()

      {:ok, _} =
        %Event{}
        |> Event.changeset(%{
          event_type: "inventory.quantity_updated",
          aggregate_id: "SKU-TIME",
          aggregate_type: "product",
          version: 3,
          payload: %{"new_quantity" => 25},
          occurred_at: now
        })
        |> Repo.insert()

      # Query state at different points
      state_at_past = EventStore.state_at("SKU-TIME", past)
      state_at_middle = EventStore.state_at("SKU-TIME", middle)
      state_at_now = EventStore.state_at("SKU-TIME", now)

      assert state_at_past.quantity == 100
      assert state_at_past.version == 1

      assert state_at_middle.quantity == 50
      assert state_at_middle.version == 2

      assert state_at_now.quantity == 25
      assert state_at_now.version == 3
    end
  end

  describe "current_version/1" do
    test "returns 0 for unknown aggregate" do
      assert EventStore.current_version("UNKNOWN") == 0
    end

    test "returns current version after events" do
      EventStore.append("product.created", "SKU-001", %{})
      EventStore.append("inventory.quantity_updated", "SKU-001", %{"new_quantity" => 50})
      EventStore.append("inventory.reserved", "SKU-001", %{"quantity" => 5, "session_id" => "s1"})

      assert EventStore.current_version("SKU-001") == 3
    end
  end

  describe "events_by_type/2" do
    setup do
      EventStore.append("inventory.quantity_updated", "SKU-001", %{"new_quantity" => 50})
      EventStore.append("inventory.quantity_updated", "SKU-002", %{"new_quantity" => 75})

      EventStore.append("inventory.reserved", "SKU-001", %{"quantity" => 10, "session_id" => "s1"})

      EventStore.append("inventory.quantity_updated", "SKU-003", %{"new_quantity" => 100})
      :ok
    end

    test "returns events of specified type" do
      events = EventStore.events_by_type("inventory.quantity_updated")

      assert length(events) == 3
      assert Enum.all?(events, &(&1.event_type == "inventory.quantity_updated"))
    end

    test "returns events in descending occurred_at order" do
      events = EventStore.events_by_type("inventory.quantity_updated")

      occurred_ats = Enum.map(events, & &1.occurred_at)
      assert occurred_ats == Enum.sort(occurred_ats, {:desc, DateTime})
    end

    test "respects limit option" do
      events = EventStore.events_by_type("inventory.quantity_updated", limit: 2)
      assert length(events) == 2
    end

    test "filters by since timestamp" do
      now = DateTime.utc_now()
      since = DateTime.add(now, -1, :second)

      events = EventStore.events_by_type("inventory.quantity_updated", since: since)

      assert Enum.all?(events, fn e ->
               DateTime.compare(e.occurred_at, since) != :lt
             end)
    end
  end

  describe "events_by_aggregate_type/2" do
    setup do
      EventStore.append("product.created", "SKU-001", %{})
      EventStore.append("channel.created", "CH-001", %{"name" => "Store"})
      EventStore.append("inventory.quantity_updated", "SKU-001", %{"new_quantity" => 50})
      EventStore.append("channel.updated", "CH-001", %{"name" => "New Store"})
      :ok
    end

    test "returns events for specified aggregate type" do
      events = EventStore.events_by_aggregate_type("product")

      assert length(events) == 2
      assert Enum.all?(events, &(&1.aggregate_type == "product"))
    end

    test "respects limit option" do
      events = EventStore.events_by_aggregate_type("product", limit: 1)
      assert length(events) == 1
    end
  end

  describe "count_events/1" do
    test "returns 0 for unknown aggregate" do
      assert EventStore.count_events("UNKNOWN") == 0
    end

    test "returns correct count" do
      EventStore.append("product.created", "SKU-001", %{})
      EventStore.append("inventory.quantity_updated", "SKU-001", %{"new_quantity" => 50})
      EventStore.append("inventory.reserved", "SKU-001", %{"quantity" => 5, "session_id" => "s1"})

      assert EventStore.count_events("SKU-001") == 3
    end
  end

  describe "version conflict handling" do
    test "concurrent appends with same version cause conflict" do
      # First, create an event to establish version 1
      {:ok, _} = EventStore.append("product.created", "CONFLICT-SKU", %{})

      # Try to manually insert another event with version 1
      result =
        %Event{}
        |> Event.changeset(%{
          event_type: "inventory.quantity_updated",
          aggregate_id: "CONFLICT-SKU",
          aggregate_type: "product",
          version: 1,
          payload: %{}
        })
        |> Repo.insert()

      assert {:error, changeset} = result
      assert "version already exists for this aggregate" in errors_on(changeset).version
    end
  end
end
