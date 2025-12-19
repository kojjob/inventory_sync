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
        - [ ] `fetch_inventory/2` implementation
    - [ ] Webhook Handler (Incoming updates from Shopify)
- [ ] **Amazon Integration** (MVP)
    - [ ] Implement `AmazonAdapter` (SP-API)
        - [ ] Signing requests (AWS SigV4)
        - [ ] Feed API for inventory updates (async processing)
- [ ] **Etsy Integration** (MVP)
    - [ ] Implement `EtsyAdapter` (v3 API)
        - [ ] OAuth 2.0 flow
        - [ ] Inventory update endpoint

## Phase 3: Reliability & Performance 🚀
- [ ] **Performance Benchmarking**
    - [ ] Set up `Benchee` scenarios
    - [ ] Measure sync throughput (events per second)
    - [ ] Optimize database queries (bulk inserts/updates)
- [ ] **Fault Tolerance**
    - [ ] Implement Retry Logic (Exponential backoff for API failures)
    - [ ] Rate Limiting (Token bucket per channel to respect API limits)
    - [ ] Idempotency keys for webhook processing
- [ ] **"Black Friday Mode"**
    - [ ] Batching mechanism for high-volume updates
    - [ ] Toggle to switch between Real-time and Batched modes
- [ ] **Telemetry & Monitoring**
    - [ ] Track sync latency
    - [ ] Count successful/failed syncs per channel
    - [ ] Dashboard for system health

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
