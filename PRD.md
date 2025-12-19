# Product Requirements Document: Multi-Channel Inventory Sync Platform

## 1. Executive Summary
A real-time inventory synchronization SaaS for small e-commerce sellers (doing $10K–$50K/month). It prevents overselling by instantly propagating inventory changes across channels (Shopify, Amazon, Etsy, eBay) using Elixir/Phoenix's concurrency strengths. It fills the gap left by TradeGecko and under-supported/overpriced competitors.

## 2. Problem Statement
- **Acute Pain**: Overselling leads to canceled orders, platform penalties, and reputational damage.
- **Target Segment**: Small sellers ($10K–$50K/mo) who have outgrown spreadsheets but can't justify $300+/mo enterprise tools (Cin7, Extensiv).
- **Existing Solutions**: 
    - Cheap tools (Sumtracker) have polling delays (30-60 mins) and limited support.
    - Enterprise tools are too expensive.
    - **Gap**: Need for affordable, real-time sync.

## 3. Solution Overview
- **Core Value Prop**: "Real-time sync is non-negotiable." Speed as UX.
- **Technology Stack**: Elixir/Phoenix.
    - **GenServer per channel**: Handles API quirks (throttling, token expiry).
    - **Phoenix PubSub**: Instant cross-channel propagation.
    - **Webhooks**: Single node handling thousands of concurrent connections (vs. polling).
    - **Fault Tolerance**: `:telemetry` monitoring, auto-retries, idempotency keys.

## 4. Features

### 4.1. MVP Scope
- **Channels**:
    - Shopify (Primary)
    - Amazon
    - Etsy
- **Core Functionality**:
    - Real-time inventory sync.
    - Webhook ingestion.
    - "Black Friday Mode": Batch updates during traffic spikes to avoid throttling.
- **Deferred (v2)**:
    - eBay integration (complex API).

### 4.2. Key Technical Requirements
- **Real-time**: Sub-second propagation where possible.
- **Reliability**: Predictive retry logic (tracking failure patterns per marketplace).
- **Maintenance**: `InventoryAdapter` protocol to abstract integrations.
- **User Experience**: Proactive alerts (e.g., "Token expires in 2 days"), 1-click reconnect.

## 5. Go-to-Market & Pricing
- **Pricing Anchor**: $49–$99/month.
    - Tiered by order volume (e.g., $49 for ≤500 orders, $79 for ≤1.5k).
- **Distribution**: Shopify App Store, Reddit/Forums (ROI stories).

## 6. Architecture & Implementation Plan
- **Step 1**: Project Initialization (Done).
- **Step 2**: Create Feature Branch.
- **Step 3**: TDD & Core Components Implementation.
- **Step 4**: Integration Testing.
- **Step 5**: Performance Benchmarks.
