# RetailFlow Implementation TODO

## Implementation Timeline: 12 Weeks

**Start Date**: Week 1
**Target Completion**: Week 12
**Current Phase**: Phase 1 - Headless API Foundation

---

## Phase 1: Headless REST API Foundation (Week 1-2)

### Week 1: API Authentication & Core Setup

#### Day 1-2: API Foundation Setup
- [ ] Add API routes scope in `lib/inventory_sync_web/router.ex`
  ```elixir
  scope "/api/v1", InventorySyncWeb.Api.V1, as: :api_v1 do
    pipe_through [:api, :api_auth]
    # routes here
  end
  ```
- [ ] Create API pipeline in router with JSON parsing
- [ ] Create `lib/inventory_sync_web/plugs/api_auth.ex` - Token verification plug
- [ ] Create migration: `mix ecto.gen.migration create_api_tokens`
- [ ] Create `lib/inventory_sync/accounts/api_token.ex` schema:
  - `token_hash` (binary)
  - `name` (string)
  - `scopes` ({:array, :string})
  - `last_used_at` (utc_datetime)
  - `expires_at` (utc_datetime)
  - `belongs_to :user`
- [ ] Add token generation functions to `Accounts` context
- [ ] Write tests for API authentication

#### Day 3-5: Product & Inventory Endpoints
- [ ] Create `lib/inventory_sync_web/controllers/api/v1/product_controller.ex`
  - `index/2` - List products with pagination
  - `show/2` - Get single product
  - `create/2` - Create product
  - `update/2` - Update product
  - `delete/2` - Delete product
- [ ] Create `lib/inventory_sync_web/controllers/api/v1/inventory_controller.ex`
  - `index/2` - List inventory across channels
  - `update/2` - Update inventory by SKU
- [ ] Create JSON serializers:
  - `lib/inventory_sync_web/controllers/api/v1/product_json.ex`
  - `lib/inventory_sync_web/controllers/api/v1/inventory_json.ex`
- [ ] Implement JSON-LD format for AI compatibility
- [ ] Write request specs for all endpoints

### Week 2: Channel Endpoints & Documentation

#### Day 6-8: Channel & Reservation Endpoints
- [ ] Create `lib/inventory_sync_web/controllers/api/v1/channel_controller.ex`
  - Full CRUD operations
  - Platform-specific validation
- [ ] Create `lib/inventory_sync_web/controllers/api/v1/reservation_controller.ex` (stub)
  - `create/2` - Create reservation (stub for Phase 3)
  - `release/2` - Release reservation (stub for Phase 3)
- [ ] Add rate limiting to API endpoints
- [ ] Implement cursor-based pagination
- [ ] Write integration tests for full flow

#### Day 9-10: API Documentation
- [ ] Add `open_api_spex` to dependencies:
  ```elixir
  {:open_api_spex, "~> 3.18"}
  ```
- [ ] Create OpenAPI 3.1 spec modules
- [ ] Mount SwaggerUI at `/api/docs`
- [ ] Document all endpoints with examples
- [ ] Code review and refactor
- [ ] Update README with API documentation

### Week 1-2 Deliverables Checklist
- [ ] All API tests passing
- [ ] API authentication working with scopes
- [ ] Swagger documentation accessible
- [ ] < 100ms response time for GET endpoints
- [ ] Rate limiting functional

---

## Phase 2: Event Sourcing Infrastructure (Week 3)

### Week 3: Event Store Implementation

#### Day 1-2: Event Schema & Store
- [ ] Create migration: `mix ecto.gen.migration create_inventory_events`
- [ ] Create `lib/inventory_sync/events/event.ex` schema:
  - `event_type` (string)
  - `aggregate_id` (string)
  - `aggregate_type` (string)
  - `payload` (map)
  - `metadata` (map)
  - `version` (integer)
  - `occurred_at` (utc_datetime_usec)
  - `belongs_to :tenant` (prep for multi-tenant)
- [ ] Create `lib/inventory_sync/events/event_store.ex`:
  - `append/4` - Append event to store
  - `stream/2` - Get event stream for aggregate
  - `replay/1` - Rebuild state from events
  - `state_at/2` - Time-travel query

#### Day 3-4: Event Types & Projectors
- [ ] Define event types:
  - `inventory.quantity_updated`
  - `inventory.reserved`
  - `inventory.reservation_committed`
  - `inventory.reservation_expired`
  - `sync.initiated`
  - `sync.completed`
  - `sync.failed`
- [ ] Create `lib/inventory_sync/events/projectors/inventory_projector.ex`
- [ ] Implement event broadcasting via PubSub
- [ ] Write tests for event store operations

#### Day 5: Integration & Testing
- [ ] Integrate event recording into existing sync flow
- [ ] Add event logging to `ChannelServer`
- [ ] Create event viewer in admin (optional)
- [ ] Performance testing for event writes
- [ ] Code review and documentation

### Week 3 Deliverables Checklist
- [ ] Event store operational
- [ ] All sync operations emit events
- [ ] Time-travel queries working
- [ ] < 10ms event append latency
- [ ] Event stream queryable

---

## Phase 3: SKU GenServers & Reservation Engine (Week 4-5)

### Week 4: SKU Server Architecture

#### Day 1-2: SKU Supervisor Setup
- [ ] Create `lib/inventory_sync/workers/sku_supervisor.ex` (DynamicSupervisor)
- [ ] Add to supervision tree in `application.ex`
- [ ] Create `lib/inventory_sync/workers/sku_server.ex` GenServer:
  - State struct: `sku`, `total_quantity`, `reserved_quantity`, `pending_reservations`, `last_synced_at`
  - `reserve/4` - Reserve quantity with TTL
  - `release/2` - Release reservation
  - `commit/2` - Convert to sale
  - `available/1` - Get available quantity
- [ ] Implement via tuple for registry lookup
- [ ] Write unit tests for SKUServer

#### Day 3-4: Reservation Schema & Logic
- [ ] Create migration: `mix ecto.gen.migration create_reservations`
- [ ] Create `lib/inventory_sync/inventory/reservation.ex`:
  - `session_id` (string)
  - `quantity` (integer)
  - `status` (enum: pending, committed, expired, released)
  - `expires_at` (utc_datetime)
  - `belongs_to :product`
- [ ] Implement reservation expiration via `Process.send_after`
- [ ] Add reservation cleanup job (Oban)
- [ ] Write tests for reservation lifecycle

### Week 5: Integration with Existing System

#### Day 1-2: ChannelServer Integration
- [ ] Modify `ChannelServer` to subscribe to SKU broadcasts
- [ ] Implement `commit_reservation/1` in Inventory context:
  - Use Ecto.Multi for transaction
  - Update product quantity
  - Mark reservation committed
  - Broadcast to channels
- [ ] Add reservation support to REST API
- [ ] Update API documentation

#### Day 3-5: Testing & Optimization
- [ ] Load test reservation system (target: 10,000/sec)
- [ ] Optimize SKUServer message handling
- [ ] Add telemetry for reservation metrics
- [ ] Integration tests for full reservation flow
- [ ] Code review and refactor

### Week 4-5 Deliverables Checklist
- [ ] SKUServer processes running per high-velocity SKU
- [ ] Reservations create/commit/expire working
- [ ] 10,000 reservations/sec throughput
- [ ] Integration with channel sync
- [ ] No overselling possible

---

## Phase 4: GraphQL API Layer (Week 6-7)

### Week 6: Absinthe Setup

#### Day 1-2: Dependencies & Schema
- [ ] Add dependencies to mix.exs:
  ```elixir
  {:absinthe, "~> 1.7"},
  {:absinthe_plug, "~> 1.5"},
  {:absinthe_phoenix, "~> 2.0"},
  {:dataloader, "~> 2.0"}
  ```
- [ ] Create `lib/inventory_sync_web/schema.ex` (root schema)
- [ ] Create type modules:
  - `lib/inventory_sync_web/schema/types/product.ex`
  - `lib/inventory_sync_web/schema/types/channel.ex`
  - `lib/inventory_sync_web/schema/types/inventory.ex`
  - `lib/inventory_sync_web/schema/types/reservation.ex`

#### Day 3-4: Queries & Mutations
- [ ] Create resolver modules:
  - `lib/inventory_sync_web/schema/resolvers/product.ex`
  - `lib/inventory_sync_web/schema/resolvers/inventory.ex`
  - `lib/inventory_sync_web/schema/resolvers/reservation.ex`
- [ ] Implement queries:
  - `product(sku: String!)` - Get by SKU
  - `products(filter: ProductFilter)` - List with pagination
  - `inventory(sku: String!)` - Get inventory status
- [ ] Implement mutations:
  - `createReservation`
  - `commitReservation`
  - `updateInventory`
- [ ] Set up Dataloader for efficient queries

### Week 7: Subscriptions & Polish

#### Day 1-2: Real-Time Subscriptions
- [ ] Create subscription modules:
  - `lib/inventory_sync_web/schema/subscriptions/inventory.ex`
- [ ] Implement subscriptions:
  - `inventoryUpdated(sku: String!)` - SKU changes
  - `flashSaleEvent` - Flash sale broadcasts
- [ ] Configure Phoenix PubSub integration
- [ ] Test WebSocket connections

#### Day 3-5: Documentation & Testing
- [ ] Mount GraphiQL at `/graphql/playground` (dev only)
- [ ] Generate SDL documentation
- [ ] Write GraphQL query tests
- [ ] Performance testing for complex queries
- [ ] Code review and optimization

### Week 6-7 Deliverables Checklist
- [ ] GraphQL endpoint operational at `/api/graphql`
- [ ] All queries, mutations working
- [ ] Real-time subscriptions functional
- [ ] Dataloader preventing N+1 queries
- [ ] GraphiQL playground available

---

## Phase 5: Multi-Tenant Architecture (Week 8-9)

### Week 8: Tenant Schema & Context

#### Day 1-2: Tenant Foundation
- [ ] Create migration: `mix ecto.gen.migration create_tenants`
- [ ] Create `lib/inventory_sync/tenants/tenant.ex`:
  - `name` (string)
  - `slug` (string, unique)
  - `plan` (enum: starter, growth, enterprise)
  - `settings` (map)
  - `data_region` (string)
- [ ] Create `lib/inventory_sync/tenants.ex` context
- [ ] Create migration: `mix ecto.gen.migration add_tenant_id_to_all_tables`

#### Day 3-4: Tenant Context Plug
- [ ] Create `lib/inventory_sync_web/plugs/tenant_context.ex`:
  - Extract tenant from subdomain
  - Extract from X-Tenant-ID header
  - Extract from API token
- [ ] Implement `Current.tenant` process dictionary storage
- [ ] Modify Repo for automatic tenant scoping
- [ ] Add tenant_id to all existing schemas

### Week 9: Row-Level Security

#### Day 1-2: Query Scoping
- [ ] Implement application-level tenant scoping
- [ ] Modify all context queries to include tenant scope
- [ ] Update API authentication to include tenant
- [ ] Test tenant isolation thoroughly

#### Day 3-5: Testing & Verification
- [ ] Create tenant isolation tests
- [ ] Test cross-tenant data access (must fail)
- [ ] Performance testing with multiple tenants
- [ ] Migration guide for existing data
- [ ] Code review and security audit

### Week 8-9 Deliverables Checklist
- [ ] Tenant schema operational
- [ ] All data scoped by tenant
- [ ] Tenant context plug working
- [ ] Zero cross-tenant data leakage
- [ ] Performance acceptable with tenant scoping

---

## Phase 6: Flash Sale System (Week 10-11)

### Week 10: Flash Sale Schema

#### Day 1-2: Schema & Migration
- [ ] Create migration: `mix ecto.gen.migration create_flash_sales`
- [ ] Create migration: `mix ecto.gen.migration create_flash_sale_products`
- [ ] Create `lib/inventory_sync/sales/flash_sale.ex`:
  - `name` (string)
  - `starts_at` (utc_datetime)
  - `ends_at` (utc_datetime)
  - `status` (enum: scheduled, active, ended)
  - `inventory_allocation` (map)
  - `many_to_many :channels`
  - `many_to_many :products`
- [ ] Create `lib/inventory_sync/sales.ex` context

#### Day 3-4: Scheduler Worker
- [ ] Create `lib/inventory_sync/workers/flash_sale_scheduler.ex` (Oban Worker)
  - Schedule sale start/end
  - Allocate inventory at start
  - Release remaining at end
- [ ] Implement inventory allocation logic
- [ ] Add SKUServer integration for flash sale quantities

### Week 11: LiveView & Real-Time

#### Day 1-2: Flash Sale LiveView
- [ ] Create `lib/inventory_sync_web/live/flash_sale_live.ex`
- [ ] Create components:
  - `countdown_component.ex` - Timer to start/end
  - `inventory_ticker.ex` - Real-time remaining count
- [ ] Implement PubSub broadcasts for flash sale events

#### Day 3-5: Testing & Polish
- [ ] Load test flash sale (simulate Black Friday)
- [ ] Verify no overselling during flash sale
- [ ] Add flash sale to GraphQL schema
- [ ] Create admin interface for flash sale management
- [ ] Code review and optimization

### Week 10-11 Deliverables Checklist
- [ ] Flash sale CRUD operational
- [ ] Scheduled start/end working
- [ ] Real-time inventory display
- [ ] No overselling during sales
- [ ] Admin management interface

---

## Phase 7: TikTok Integration Stub (Week 12)

### Week 12: TikTok Stub & Final Polish

#### Day 1-2: TikTok Adapter Stub
- [ ] Create `lib/inventory_sync/integrations/tiktok_adapter.ex`:
  - Implement behaviour with `{:error, :not_implemented}`
  - Stub OAuth URL generation
  - Stub token exchange
- [ ] Create migration: `mix ecto.gen.migration add_tiktok_to_platforms`
- [ ] Add `:tiktok` to Channel platform enum
- [ ] Document future TikTok implementation plan

#### Day 3-5: Final Polish & Performance
- [ ] Full system integration testing
- [ ] Performance optimization pass
- [ ] Security audit
- [ ] Documentation review and update
- [ ] Prepare production deployment checklist

### Week 12 Deliverables Checklist
- [ ] TikTok stub in place
- [ ] All 12-week features complete
- [ ] Performance metrics met
- [ ] Security audit passed
- [ ] Production-ready

---

## Database Migrations Checklist

| # | Migration | Week | Status |
|---|-----------|------|--------|
| 1 | `create_api_tokens` | 1 | [ ] |
| 2 | `create_inventory_events` | 3 | [ ] |
| 3 | `create_reservations` | 4 | [ ] |
| 4 | `create_tenants` | 8 | [ ] |
| 5 | `add_tenant_id_to_all_tables` | 8 | [ ] |
| 6 | `create_flash_sales` | 10 | [ ] |
| 7 | `create_flash_sale_products` | 10 | [ ] |
| 8 | `add_tiktok_to_platforms` | 12 | [ ] |

---

## Dependencies to Add

```elixir
# mix.exs - Add to deps
{:open_api_spex, "~> 3.18"},     # Week 2 - OpenAPI
{:absinthe, "~> 1.7"},           # Week 6 - GraphQL
{:absinthe_plug, "~> 1.5"},      # Week 6 - GraphQL
{:absinthe_phoenix, "~> 2.0"},   # Week 6 - GraphQL subscriptions
{:dataloader, "~> 2.0"}          # Week 6 - Efficient data loading
```

---

## Success Metrics

| Metric | Target | Test Method |
|--------|--------|-------------|
| API Response Time | < 100ms p95 | Load test |
| Reservation Throughput | 10,000/sec | Load test |
| Sync Latency | < 500ms | Channel sync timing |
| Flash Sale Accuracy | 100% no oversell | Audit log |
| Test Coverage | > 85% | `mix coveralls` |

---

## Quick Reference Commands

```bash
# Development
mix setup                    # Initial setup
mix phx.server              # Start server
iex -S mix phx.server       # Start with IEx

# Testing
mix test                    # Run all tests
mix test --cover            # With coverage
mix test path/to/test.exs:42  # Specific test

# Database
mix ecto.gen.migration name # New migration
mix ecto.migrate            # Run migrations
mix ecto.rollback           # Rollback last
mix ecto.reset              # Nuclear reset

# Quality
mix format                  # Format code
mix credo                   # Static analysis
mix dialyzer                # Type checking
```

---

## Notes & Decisions Log

### Dec 26, 2025 - Project Kickoff
- **Decision**: API First approach selected
- **Decision**: 12-week complete implementation timeline
- **Decision**: TikTok deprioritized (stub only)
- **Decision**: GraphQL, Multi-tenant, Event Sourcing are MUST-HAVES
- **Reference**: Full plan in `docs/RETAILFLOW_PLAN.md`

---

*Last Updated: Dec 26, 2025*
