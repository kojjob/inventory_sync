# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**InventorySync** is a B2B SaaS platform for real-time multi-channel inventory synchronization. It connects inventory sources with sales channels (Shopify, Amazon, Etsy) using an OTP-based architecture with GenServers, PubSub, and Phoenix LiveView.

**Current Status**: Pre-alpha (v0.8.0) - Core functionality works but lacks production-ready security features. See `TODO.md` for critical blockers.

## Quick Reference

### Common Tasks
```bash
# Development workflow
mix setup && mix phx.server     # Full setup and start server
mix test && mix format          # Test and format before commit

# Database work
mix ecto.reset                  # Nuclear option: drop/create/migrate
mix ecto.gen.migration name     # Create new migration

# Debugging
iex -S mix phx.server           # Start with IEx for debugging
iex> :observer.start()          # Visual process tree and monitoring
```

### Key Files
- `lib/inventory_sync/inventory.ex` - Main context (CRUD operations)
- `lib/inventory_sync/workers/channel_server.ex` - Per-channel GenServer with rate limiting
- `lib/inventory_sync/application.ex` - OTP supervision tree
- `config/test.exs` - Test configuration (MockAdapter enabled)

## Core Development Commands

### Initial Setup
```bash
mix setup                    # Install deps, setup DB, build assets
mix phx.server              # Start development server (localhost:4000)
iex -S mix phx.server       # Start server with IEx console
```

### Testing
```bash
mix test                     # Run all tests
mix test path/to/test.exs   # Run single test file
mix test path/to/test.exs:42 # Run specific test at line 42
```

### Database Operations
```bash
mix ecto.create             # Create database
mix ecto.migrate            # Run migrations
mix ecto.rollback           # Rollback last migration
mix ecto.reset              # Drop, create, and migrate database
```

### Code Quality
```bash
mix format                  # Format code
mix compile --warnings-as-errors  # Strict compilation
mix precommit               # Run full pre-commit checks (compile, format, test)
```

### Asset Management
```bash
mix assets.build            # Build Tailwind CSS and esbuild assets
mix assets.deploy           # Minified production build
```

## Architecture Overview

### OTP Supervision Tree

The application follows a hierarchical supervision strategy:

```
InventorySync.Application
├── InventorySyncWeb.Telemetry
├── InventorySync.Repo (Database)
├── Phoenix.PubSub (Event bus)
├── Registry (ChannelRegistry - unique channel process lookup)
├── InventorySync.Workers.SyncManager (DynamicSupervisor)
│   └── InventorySync.Workers.ChannelServer (1 per channel, GenServer)
├── InventorySync.Workers.Bootstrapper (Auto-starts ChannelServers)
└── InventorySyncWeb.Endpoint (Phoenix HTTP)
```

**Key Insight**: Each sales channel gets its own supervised `ChannelServer` GenServer that manages rate limiting and sync operations independently.

### Data Flow Architecture

**Inventory Update Flow**:
1. User updates product quantity via LiveView or webhook receives external change
2. `Inventory.update_product_quantity/2` updates database in transaction
3. PubSub broadcasts `{:sync_inventory, item}` to `"channel:#{channel_id}"` topic
4. Each `ChannelServer` subscribed to that topic receives message
5. `ChannelServer` applies token bucket rate limiting
6. Adapter (Shopify/Amazon/Etsy) makes API call to external platform
7. `SyncHistory` record created, telemetry events emitted
8. LiveView dashboard updates via PubSub broadcast to `"inventory_updates"`

### Domain Model

The core entities and their relationships:

```
Product (master inventory)
├── sku: string (unique)
├── name: string
├── total_quantity: integer (source of truth)
└── has_many inventory_items

InventoryItem (channel-specific allocation)
├── belongs_to product
├── belongs_to channel
├── platform_sku: string (channel's SKU, may differ from product.sku)
├── quantity: integer (synced to channel)
└── updated_at: timestamp

Channel (external platform connection)
├── name: string
├── platform: enum (:shopify | :amazon | :etsy)
├── credentials: map (UNENCRYPTED - security blocker!)
├── active: boolean
└── has_many inventory_items
```

**Key Pattern**: `Product` holds master quantity. Each `InventoryItem` links a product to a channel and tracks the synced quantity for that specific platform. When product quantity changes, ALL linked inventory items are updated and synced.

### Context Boundaries

- **`InventorySync.Inventory`**: Core domain context - CRUD for Channels, Products, InventoryItems, Users, Settings, SyncHistory
- **`InventorySync.Workers`**: OTP workers for sync orchestration (SyncManager, ChannelServer, Bootstrapper)
- **`InventorySync.Integrations`**: Adapter behaviour and implementations for external platforms
- **`InventorySyncWeb`**: Phoenix web layer - LiveViews, Controllers, Components

### Adapter Pattern

All platform integrations implement `InventorySync.Integrations.InventoryAdapter` behaviour:

```elixir
@callback update_inventory(credentials :: map(), item :: map(), quantity :: integer()) ::
            {:ok, any()} | {:error, any()}

@callback fetch_inventory(credentials :: map(), item :: map()) ::
            {:ok, integer()} | {:error, any()}
```

**Adapters**:
- `ShopifyAdapter`: Full implementation with real API calls
- `AmazonAdapter`, `EtsyAdapter`: Stub implementations
- `MockAdapter`: Used in tests (controlled by `:use_mock_adapter` config)

### Process Management & Registry Pattern

**ChannelServer Lifecycle**:
1. `Bootstrapper` queries all active channels from database on app start
2. For each channel, `SyncManager.start_channel/1` spawns a supervised `ChannelServer`
3. Each `ChannelServer` registers itself via `Registry` with `{ChannelRegistry, channel_id}`
4. Process lookup uses `via_tuple/1`: `{:via, Registry, {InventorySync.ChannelRegistry, channel_id}}`

**Why Registry?** Allows named GenServer processes without hardcoded atoms. Each channel gets a unique, dynamically-named process that can be looked up by channel ID.

**Example Process Communication**:
```elixir
# Send message to specific channel's GenServer
ChannelServer.via_tuple(channel_id)
|> GenServer.call({:update_inventory, item, quantity})

# Registry automatically routes to the correct process
```

**Supervision Strategy**: `:one_for_one` - If a `ChannelServer` crashes, only that channel's process restarts. Other channels continue operating independently.

### Rate Limiting Strategy

`ChannelServer` implements token bucket algorithm:
- **Max tokens**: 2.0
- **Refill rate**: 2.0 tokens/second
- **Behavior**: Requests consume 1 token; if insufficient tokens, message is requeued with 1s delay
- **Platform limits**: Configurable per channel type (Shopify allows 2req/s with burst of 40)

**Implementation Detail**: Rate limiting happens in `handle_info({:sync_inventory, item}, state)`. State tracks `tokens`, `last_refill`, and calculates token replenishment based on elapsed time.

### Testing Configuration

Tests use `Ecto.Adapters.SQL.Sandbox` for database isolation. Key test environment settings:

- `config :inventory_sync, :use_mock_adapter, true` - Forces `MockAdapter` for all tests
- Database: `inventory_sync_test` with partition support via `MIX_TEST_PARTITION`
- HTTP endpoint runs on port 4002 with `server: false`

**Test helpers** in `test/support/`:
- `test/support/fixtures/*.ex` - Data factories for tests
- `test/support/conn_case.ex` - Controller test helpers
- `test/support/data_case.ex` - Database test helpers

## Development Guidelines

### Adding a New Sales Channel

1. Create adapter module in `lib/inventory_sync/integrations/`:
   ```elixir
   defmodule InventorySync.Integrations.NewChannelAdapter do
     @behaviour InventorySync.Integrations.InventoryAdapter

     @impl true
     def update_inventory(credentials, item, quantity) do
       # Implementation
     end

     @impl true
     def fetch_inventory(credentials, item) do
       # Implementation
     end
   end
   ```

2. Update `ChannelServer.adapter_for/1` to map platform atom to adapter module

3. Add platform to `Channel` schema enum: `:shopify | :amazon | :etsy | :new_channel`

4. Write adapter tests in `test/inventory_sync/integrations/`

### Database Migrations

- Migrations are in `priv/repo/migrations/`
- Use descriptive names: `YYYYMMDDHHMMSS_create_table_name.exs`
- Always make migrations reversible (define `down/0` or use reversible operations)
- Test rollback: `mix ecto.rollback && mix ecto.migrate`

### LiveView Components

- Core reusable components in `lib/inventory_sync_web/components/core_components.ex`
- Page-specific LiveViews in `lib/inventory_sync_web/live/*/`
- Use `Phoenix.Component` for stateless UI components
- Use `Phoenix.LiveView` for stateful real-time pages

### PubSub Topics

- `"channel:#{channel_id}"` - Inventory sync messages for specific channel
- `"inventory_updates"` - Broadcast sync events to dashboard for real-time UI updates

### Webhook Integration

**Endpoint**: `POST /api/webhooks/shopify` (defined in `WebhookController`)

**Flow**:
1. External platform (e.g., Shopify) sends inventory update webhook
2. `WebhookController.shopify/2` receives POST request
3. ⚠️ **SECURITY ISSUE**: Currently no HMAC signature verification (see TODO.md blocker B-02)
4. Controller updates product/inventory item in database
5. This triggers the normal sync flow to other channels via PubSub

**Current State**: Synchronous processing (request blocks until complete). Should be moved to async job queue (Oban) to prevent timeouts.

### Configuration & Environment

Configuration is split across multiple files:

- `config/config.exs` - Shared config (Ecto, Phoenix, etc.)
- `config/dev.exs` - Development-specific (live reload, debug logging)
- `config/test.exs` - Test environment (MockAdapter enabled, sandbox mode)
- `config/prod.exs` - Production settings (minimal, most config in runtime.exs)
- `config/runtime.exs` - Runtime configuration from environment variables

**Key Configuration Points**:
```elixir
# Force MockAdapter in tests (config/test.exs)
config :inventory_sync, :use_mock_adapter, true

# Database configuration (config/runtime.exs)
config :inventory_sync, InventorySync.Repo,
  url: System.get_env("DATABASE_URL")

# Secret key base (config/runtime.exs)
config :inventory_sync, InventorySyncWeb.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE")
```

**Environment Variables** (see `config/runtime.exs` for full list):
- `DATABASE_URL` - PostgreSQL connection string
- `SECRET_KEY_BASE` - Phoenix secret (run `mix phx.gen.secret`)
- `PHX_HOST` - Production hostname

## Critical Security Notes (from TODO.md)

⚠️ **This application is NOT production-ready**. Critical blockers:

1. **No Authentication** - Dashboard is publicly accessible
2. **Insecure Webhooks** - Missing HMAC signature verification
3. **Infinite Retries** - Worker can exhaust resources on persistent failures
4. **Plain Text Secrets** - API credentials stored unencrypted in database
5. **Synchronous Webhooks** - Request timeout risk under load

Before deploying, complete P0 tasks in `TODO.md`.

## Debugging & Troubleshooting

### Inspecting Running Processes

```elixir
# In IEx console
iex> Registry.lookup(InventorySync.ChannelRegistry, channel_id)
# Returns: [{pid, value}] or [] if not found

iex> :sys.get_state(pid)
# Shows current GenServer state (tokens, channel info, etc.)

iex> Process.info(pid)
# Memory, message queue length, etc.
```

### Observer for Visual Debugging

```elixir
iex> :observer.start()
```
Navigate to Applications tab to see the supervision tree visually. Useful for identifying:
- Which ChannelServers are running
- Process memory consumption
- Message queue backlogs (sign of performance issues)

### Common Issues

**Problem**: Inventory sync not happening
```elixir
# Check if ChannelServer is running
iex> Registry.lookup(InventorySync.ChannelRegistry, channel_id)

# Check if channel is active in database
iex> InventorySync.Inventory.get_channel!(channel_id)

# Verify PubSub subscription
iex> Phoenix.PubSub.subscribers(InventorySync.PubSub, "channel:#{channel_id}")
```

**Problem**: Rate limiting issues
```elixir
# Check current token state
iex> pid = Registry.lookup(InventorySync.ChannelRegistry, channel_id) |> List.first() |> elem(0)
iex> :sys.get_state(pid).tokens
```

**Problem**: Tests failing with database errors
```bash
# Reset test database
MIX_ENV=test mix ecto.reset

# Ensure Sandbox mode is enabled in test.exs
config :inventory_sync, InventorySync.Repo,
  pool: Ecto.Adapters.SQL.Sandbox
```

### Telemetry & Monitoring

View live metrics at `/dev/dashboard` in development. Key metrics:
- `inventory_sync.worker.sync_success` - Count and duration
- `inventory_sync.worker.sync_failure` - Errors by channel/SKU
- `inventory_sync.worker.rate_limited` - Rate limit hits

## Working with This Codebase

### Context Module Pattern

The codebase follows Phoenix's recommended context pattern. The `Inventory` context aggregates all domain operations:

- Never bypass contexts to access Repo directly in controllers/LiveViews
- Add new operations to `InventorySync.Inventory` rather than creating ad-hoc queries
- Contexts return `{:ok, struct}` or `{:error, changeset}` tuples

**Example - Correct Pattern**:
```elixir
# In LiveView
def handle_event("update_quantity", %{"quantity" => qty}, socket) do
  case Inventory.update_product_quantity(product.id, qty) do
    {:ok, product} -> {:noreply, assign(socket, :product, product)}
    {:error, _} -> {:noreply, put_flash(socket, :error, "Update failed")}
  end
end

# DON'T DO THIS - bypasses context
product |> Ecto.Changeset.change(%{quantity: qty}) |> Repo.update!()
```

### Telemetry Events

Application emits telemetry events for monitoring:

- `[:inventory_sync, :worker, :sync_success]` - Successful inventory sync
- `[:inventory_sync, :worker, :sync_failure]` - Failed sync attempt
- `[:inventory_sync, :worker, :rate_limited]` - Rate limit hit

Access via `InventorySyncWeb.Telemetry` or LiveDashboard at `/dev/dashboard`

### Error Handling in Workers

`ChannelServer` implements retry with exponential backoff (currently 5s fixed, needs improvement):

```elixir
# TODO: Should implement exponential backoff (2^n)
Process.send_after(self(), {:sync_inventory, item}, 5000)
```

Failed syncs create `SyncHistory` records with `status: "error"` for audit trail.

### Transaction Patterns & Ecto Best Practices

**Multi-Step Operations Use Ecto.Multi**:

The `update_product_quantity/2` function demonstrates proper transaction handling:

```elixir
def update_product_quantity(product_id, new_quantity) do
  product = get_product!(product_id)

  Ecto.Multi.new()
  |> Ecto.Multi.update(:product, Product.changeset(product, %{total_quantity: new_quantity}))
  |> Ecto.Multi.run(:inventory_items, fn repo, _ ->
      items = repo.all(from i in InventoryItem, where: i.product_id == ^product.id, preload: [:channel])
      repo.update_all(from(i in InventoryItem, where: i.product_id == ^product.id),
        set: [quantity: new_quantity, updated_at: DateTime.utc_now()]
      )
      {:ok, items}
    end)
  |> Repo.transaction()
  |> case do
      {:ok, %{product: product, inventory_items: items}} ->
        # Broadcast to channels AFTER successful transaction
        Enum.each(items, fn item ->
          Phoenix.PubSub.broadcast(InventorySync.PubSub, "channel:#{item.channel_id}",
            {:sync_inventory, %{item | quantity: new_quantity}})
        end)
        {:ok, product}
      error -> error
    end
end
```

**Key Patterns**:
1. **Atomicity**: Database updates wrapped in transaction - all succeed or all rollback
2. **Side Effects After Commit**: PubSub broadcasts happen ONLY after successful transaction
3. **Preloading**: Load associations efficiently with `preload: [:channel]`
4. **Bulk Updates**: Use `update_all` for multiple records instead of iterating

**Changeset Validation**:
- Always use changesets for data validation
- `validate_required/2`, `unique_constraint/2`, `validate_format/2`, etc.
- Return `{:ok, struct}` or `{:error, changeset}` - never raise in contexts

## Phoenix-Specific Notes

### LiveView Architecture

**NavHook Pattern**: All LiveView pages use `on_mount: InventorySyncWeb.NavHook` to track active navigation state.

```elixir
# In router.ex
live_session :default, on_mount: InventorySyncWeb.NavHook do
  live "/", DashboardLive
  live "/products", ProductLive.Index, :index
  # ... other routes
end
```

The NavHook sets the current route in socket assigns, used for highlighting active nav items in the layout.

**Real-Time Updates Pattern**:
```elixir
# In LiveView mount/3
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(InventorySync.PubSub, "inventory_updates")
  end
  {:ok, socket}
end

# Handle broadcasts
def handle_info({:sync_event, history}, socket) do
  # Update socket assigns, LiveView automatically re-renders
  {:noreply, update(socket, :sync_history, &[history | &1])}
end
```

**LiveView Testing**:
- Use `live/2` from `Phoenix.LiveViewTest` to simulate user interactions
- `render_click`, `render_submit`, `render_change` for form interactions
- `assert_patch`, `assert_redirect` for navigation testing

### Other Phoenix Details

- **Endpoint**: `InventorySyncWeb.Endpoint` configured in `config/config.exs`, `config/dev.exs`, etc.
- **Router**: `lib/inventory_sync_web/router.ex` - defines `browser` and `api` pipelines
- **Layouts**: Component-based layouts in `lib/inventory_sync_web/components/layouts.ex`
- **Static Assets**: Tailwind CSS + esbuild, managed via `assets.build` mix alias
- **Component Library**: Reusable UI components in `core_components.ex` (buttons, modals, tables, etc.)
