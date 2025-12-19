# Project Roadmap & TODOs

## Phase 1: Foundation (Core Logic) 🏗️
- [x] **Project Initialization**
    - [x] Phoenix app scaffold (`mix phx.new`)
    - [x] Database setup (PostgreSQL)
    - [x] Git repository setup
- [x] **Core Data Models**
    - [x] `Channel` schema (stores credentials, platform type)
    - [x] `Product` schema (SKU, total quantity)
    - [x] `InventoryItem` schema (links Product <-> Channel)
    - [x] Database migrations & associations
- [x] **Sync Architecture (Internal)**
    - [x] `InventoryAdapter` behaviour definition
    - [x] `ChannelServer` (GenServer) for per-channel state management
    - [x] `SyncManager` (DynamicSupervisor) for worker lifecycle
    - [x] `Phoenix.PubSub` integration for broadcasting updates
    - [x] **Integration Test**: Verify `Update Product -> PubSub -> Worker -> Adapter` flow

## Phase 2: Platform Integrations 🔌
- [x] **Shopify Integration**
    - [x] Implement `ShopifyAdapter` (Real API calls)
        - [x] Authentication (Access Token handling)
        - [x] `update_inventory/3` implementation
        - [x] `fetch_inventory/2` implementation
    - [x] Webhook Handler (Incoming updates from Shopify)
- [x] **Amazon Integration** (MVP)
    - [x] Implement `AmazonAdapter` Stub
    - [ ] Implement `AmazonAdapter` (SP-API)
        - [ ] Signing requests (AWS SigV4)
        - [ ] Feed API for inventory updates (async processing)
- [x] **Etsy Integration** (MVP)
    - [x] Implement `EtsyAdapter` Stub
    - [ ] Implement `EtsyAdapter` (v3 API)
        - [ ] OAuth 2.0 flow
        - [ ] Inventory update endpoint

## Phase 3: Reliability & Performance 🚀
- [x] **Performance Benchmarking**
    - [x] Set up `Benchee` scenarios
    - [x] Measure sync throughput (events per second)
        - *Result*: ~678 syncs/sec with fan-out to 5 channels (Local DB, Mock Adapter)
    - [ ] Optimize database queries (bulk inserts/updates)
- [x] **Fault Tolerance**
    - [x] Implement Retry Logic (Simple exponential backoff simulation)
    - [x] Rate Limiting (Token bucket per channel)
    - [ ] Idempotency keys for webhook processing
- [ ] **"Black Friday Mode"**
    - [ ] Batching mechanism for high-volume updates
    - [ ] Toggle to switch between Real-time and Batched modes
- [x] **Telemetry & Monitoring**
    - [x] Track sync latency
    - [x] Count successful/failed syncs per channel
    - [x] Dashboard for system health (Phoenix LiveDashboard configured)

## Phase 4: Webhook Ingestion (Incoming) 📥
- [ ] **Webhook Endpoints**
    - [ ] Generic webhook controller
    - [ ] Signature verification (Security)
- [ ] **Processing Pipeline**
    - [ ] Parse incoming payload -> Update `Product` quantity -> Trigger Sync (Fan-out)

## Phase 5: User Interface (Phoenix LiveView) 🖥️
- [ ] **Dashboard**
    - [ ] Real-time view of active channels
    - [ ] Recent sync activity log
- [ ] **Channel Configuration**
    - [ ] Add/Edit/Remove Channels
    - [ ] OAuth callback pages
- [ ] **Inventory Management**
    - [ ] Manual override of inventory levels
    - [ ] Product mapping (SKU matching)

## Phase 6: Deployment & Operations ☁️
- [ ] **CI/CD Pipeline**
    - [ ] GitHub Actions for tests and formatting
- [ ] **Production Environment**
    - [ ] Dockerfile setup
    - [ ] Fly.io / Gigalixir configuration
- [ ] **Security Review**
    - [ ] Credential encryption (Vault or similar)
    - [ ] Rate limiting for incoming webhooks
