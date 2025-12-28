# RetailFlow Consolidation Plan

## Executive Summary

**Goal:** Transform InventorySync into RetailFlow - a high-concurrency inventory sync engine with sub-second stock truth, in-memory reservations, and headless API capabilities.

**Current State:** InventorySync is ~80% production-ready with:
- OTP supervision tree (ChannelServer per channel)
- PubSub-driven real-time sync
- Oban background jobs with retry logic
- Full authentication & encrypted credentials
- Shopify adapter (Amazon/Etsy stubs)

**User Decisions (Dec 26, 2025):**
- API First approach
- 12-week complete implementation timeline
- TikTok deprioritized (stub now, full integration later)
- Advanced features are MUST-HAVES: GraphQL, Multi-tenant, Event Sourcing

**Revised Priority Matrix:**
| Feature | Priority | Effort | Week | Status |
|---------|----------|--------|------|--------|
| Headless REST API | P0 | 2 weeks | 1-2 | Missing |
| Event Sourcing Infrastructure | P0 | 1 week | 3 | Missing |
| SKU GenServers (Reservations) | P0 | 2 weeks | 4-5 | Missing |
| GraphQL API Layer | P0 | 2 weeks | 6-7 | Missing |
| Multi-tenant Architecture | P0 | 2 weeks | 8-9 | Missing |
| Flash Sale System | P1 | 2 weeks | 10-11 | Missing |
| TikTok Integration (Stub) | P2 | 1 week | 12 | Missing |

---

## Phase 1: Headless API Foundation (Week 1-2)

### 1.1 API Authentication Layer
**Files to create/modify:**
- `lib/inventory_sync/accounts/api_token.ex` - API token schema
- `lib/inventory_sync_web/plugs/api_auth.ex` - Token verification plug
- `priv/repo/migrations/YYYYMMDD_create_api_tokens.exs`

**Schema:**
```elixir
defmodule InventorySync.Accounts.ApiToken do
  schema "api_tokens" do
    field :token_hash, :binary
    field :name, :string
    field :scopes, {:array, :string}  # ["read:products", "write:inventory"]
    field :last_used_at, :utc_datetime
    field :expires_at, :utc_datetime
    belongs_to :user, InventorySync.Accounts.User
    timestamps()
  end
end
```

### 1.2 RESTful API Endpoints
**Files to create:**
- `lib/inventory_sync_web/controllers/api/v1/product_controller.ex`
- `lib/inventory_sync_web/controllers/api/v1/inventory_controller.ex`
- `lib/inventory_sync_web/controllers/api/v1/channel_controller.ex`
- `lib/inventory_sync_web/controllers/api/v1/reservation_controller.ex`

**Routes (in router.ex):**
```elixir
scope "/api/v1", InventorySyncWeb.Api.V1, as: :api_v1 do
  pipe_through [:api, :api_auth]

  resources "/products", ProductController, except: [:new, :edit]
  resources "/channels", ChannelController, except: [:new, :edit]

  # Inventory operations
  get "/inventory", InventoryController, :index
  put "/inventory/:sku", InventoryController, :update

  # Reservations (Phase 2 prerequisite)
  post "/reservations", ReservationController, :create
  delete "/reservations/:id", ReservationController, :release
end
```

### 1.3 JSON Serialization
**Files to create:**
- `lib/inventory_sync_web/controllers/api/v1/product_json.ex`
- `lib/inventory_sync_web/controllers/api/v1/inventory_json.ex`

**JSON-LD Format (for Agentic AI compatibility):**
```json
{
  "@context": "https://schema.org",
  "@type": "Product",
  "sku": "ABC-123",
  "name": "Widget Pro",
  "inventory": {
    "available": 150,
    "reserved": 25,
    "total": 175
  }
}
```

### 1.4 API Documentation
- OpenAPI 3.1 spec at `/api/docs`
- SwaggerUI integration via `open_api_spex`

---

## Phase 2: Event Sourcing Infrastructure (Week 3)

### 2.1 Event Store Schema

**Files to create:**
- `lib/inventory_sync/events/event.ex` - Base event schema
- `lib/inventory_sync/events/event_store.ex` - Event persistence layer
- `lib/inventory_sync/events/projectors/inventory_projector.ex` - Rebuild state from events
- `priv/repo/migrations/YYYYMMDD_create_inventory_events.exs`

**Event Schema:**
```elixir
defmodule InventorySync.Events.Event do
  schema "inventory_events" do
    field :event_type, :string
    field :aggregate_id, :string
    field :aggregate_type, :string
    field :payload, :map
    field :metadata, :map
    field :version, :integer
    field :occurred_at, :utc_datetime_usec
    belongs_to :tenant, InventorySync.Tenants.Tenant
    timestamps(type: :utc_datetime_usec)
  end
end
```

**Event Types:**
- `inventory.quantity_updated` - Stock level changed
- `inventory.reserved` - Quantity reserved for session
- `inventory.reservation_committed` - Reservation converted to sale
- `inventory.reservation_expired` - Reservation TTL exceeded
- `sync.initiated` - Channel sync started
- `sync.completed` - Channel sync finished
- `sync.failed` - Channel sync error

---

## Phase 3: SKU GenServers & Reservation Engine (Week 4-5)

### 3.1 SKU Server Architecture

**Supervision Tree Addition:**
```
InventorySync.Application
├── ...existing supervisors...
├── InventorySync.Workers.SKUSupervisor (DynamicSupervisor)
│   └── InventorySync.Workers.SKUServer (per high-velocity SKU)
```

**Files to create:**
- `lib/inventory_sync/workers/sku_supervisor.ex`
- `lib/inventory_sync/workers/sku_server.ex`
- `lib/inventory_sync/inventory/reservation.ex`
- `priv/repo/migrations/YYYYMMDD_create_reservations.exs`

### 3.2 SKUServer GenServer Implementation

```elixir
defmodule InventorySync.Workers.SKUServer do
  use GenServer

  defstruct [
    :sku,
    :total_quantity,
    :reserved_quantity,
    :pending_reservations,
    :last_synced_at
  ]

  # Public API
  def reserve(sku, session_id, quantity, ttl_seconds \\ 900)
  def release(sku, session_id)
  def commit(sku, session_id)
  def available(sku)
end
```

---

## Phase 4: GraphQL API Layer (Week 6-7)

### 4.1 Absinthe Setup

**Files to create:**
- `lib/inventory_sync_web/schema.ex` - Root schema
- `lib/inventory_sync_web/schema/types/*.ex` - Object types
- `lib/inventory_sync_web/schema/resolvers/*.ex` - Resolvers
- `lib/inventory_sync_web/schema/subscriptions/*.ex` - Real-time subscriptions

**Dependencies to add (mix.exs):**
```elixir
{:absinthe, "~> 1.7"},
{:absinthe_plug, "~> 1.5"},
{:absinthe_phoenix, "~> 2.0"},
{:dataloader, "~> 2.0"}
```

---

## Phase 5: Multi-Tenant Architecture (Week 8-9)

### 5.1 Tenant Schema

**Files to create:**
- `lib/inventory_sync/tenants/tenant.ex`
- `lib/inventory_sync/tenants.ex` (context)
- `lib/inventory_sync_web/plugs/tenant_context.ex`
- `priv/repo/migrations/YYYYMMDD_create_tenants.exs`
- `priv/repo/migrations/YYYYMMDD_add_tenant_id_to_all_tables.exs`

---

## Phase 6: Flash Sale System (Week 10-11)

### 6.1 Flash Sale Schema

**Files to create:**
- `lib/inventory_sync/sales/flash_sale.ex`
- `lib/inventory_sync/sales.ex` (context)
- `lib/inventory_sync/workers/flash_sale_scheduler.ex`
- `lib/inventory_sync_web/live/flash_sale_live.ex`
- `priv/repo/migrations/YYYYMMDD_create_flash_sales.exs`

---

## Phase 7: TikTok Integration Stub (Week 12)

### 7.1 Stub Adapter

**Files to create:**
- `lib/inventory_sync/integrations/tiktok_adapter.ex`

---

## Database Migrations Required

1. `create_api_tokens.exs`
2. `create_inventory_events.exs`
3. `create_reservations.exs`
4. `create_tenants.exs`
5. `add_tenant_id_to_all_tables.exs`
6. `create_flash_sales.exs`
7. `create_flash_sale_products.exs` (join table)
8. `add_tiktok_to_platforms.exs`

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| API Response Time | < 100ms p95 | Telemetry |
| Reservation Throughput | 10,000/sec | Load test |
| Sync Latency | < 500ms | Channel sync time |
| Flash Sale Accuracy | 100% no oversell | Audit log |

---

## Summary: What You're Building

**RetailFlow** = InventorySync + Enterprise Features

| Component | InventorySync (Current) | RetailFlow (Target) |
|-----------|------------------------|---------------------|
| **API** | LiveView only | REST + GraphQL + WebSockets |
| **State** | Database-backed | In-memory GenServers + DB |
| **Tenancy** | Single-tenant | Multi-tenant with isolation |
| **Audit** | SyncHistory table | Full event sourcing |
| **Channels** | Shopify, Amazon, Etsy | + TikTok, Flash Sales |
| **Reservations** | None | SKU-level with TTL |

**Total Effort:** 12 weeks
**New Files:** ~50+ (schemas, controllers, workers, tests)
**New Migrations:** 8
**New Dependencies:** 4 (absinthe, dataloader, open_api_spex, jason)
