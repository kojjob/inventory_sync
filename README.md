# Inventory Sync

A real-time, multi-channel inventory synchronization platform built with Elixir and Phoenix. This SaaS solution ensures stock levels are accurate across multiple sales channels (Shopify, Amazon, Etsy), preventing overselling and improving operational efficiency for small to medium-sized e-commerce sellers.

## 🚀 Key Features

- **Real-Time Synchronization**: Sub-second inventory propagation across channels using Phoenix PubSub and GenServers.
- **Multi-Channel Support**: Integrated with Shopify (Full), with Amazon and Etsy support (Stubs).
- **Reliable Webhook Ingestion**: Securely handles incoming webhooks with HMAC signature verification.
- **Fault Tolerance**: Predictive retry logic with exponential backoff for API failures.
- **Async Processing**: Background job processing using Oban for high-throughput webhook handling.
- **Security First**: 
  - Sensitive credentials encrypted at rest using AES-GCM via Cloak.Ecto
  - API tokens protected with rate limiting (5 failed attempts/IP/minute)
  - SHA256 token hashing for secure authentication
- **Modern UI**: Polished dashboard and management interface built with Phoenix LiveView and Tailwind CSS v4.

## 🛠️ Tech Stack

- **Language**: [Elixir](https://elixir-lang.org/)
- **Framework**: [Phoenix](https://www.phoenixframework.org/) (v1.8+)
- **Frontend**: [LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html), [Tailwind CSS v4](https://tailwindcss.com/)
- **Database**: [PostgreSQL](https://www.postgresql.org/) with [Ecto](https://hexdocs.pm/ecto/Ecto.html)
- **Background Jobs**: [Oban](https://getoban.pro/)
- **Encryption**: [Cloak.Ecto](https://hexdocs.pm/cloak_ecto/Cloak.Ecto.html)
- **HTTP Client**: [Req](https://hexdocs.pm/req/Req.html)
- **Testing**: [Bypass](https://hexdocs.pm/bypass/Bypass.html) (HTTP mocking), [LazyHTML](https://hexdocs.pm/lazy_html/LazyHTML.html) (LiveView testing)

## 🏁 Getting Started

### Prerequisites

- Elixir 1.15+
- Erlang/OTP 26+
- PostgreSQL 14+

### Setup

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/kojjob/inventory_sync.git
    cd inventory_sync
    ```

2.  **Install and setup dependencies**:
    ```bash
    mix setup
    ```
    This command will install Hex/Rebar, fetch dependencies, create and migrate the database, and build assets.

3.  **Start the Phoenix server**:
    ```bash
    mix phx.server
    ```
    Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## 🏗️ Architecture Overview

The application follows a hierarchical supervision strategy to ensure high availability and fault tolerance:

- **`InventorySync.Application`**: The root of the supervision tree.
- **`ChannelRegistry`**: A unique registry for looking up per-channel processes.
- **`SyncManager`**: A DynamicSupervisor that manages `ChannelServer` processes.
- **`ChannelServer`**: A GenServer per active channel that manages state, token-bucket rate limiting, and retries.
- **`InventoryAdapter`**: A behaviour that abstracts channel-specific API logic (Shopify, Amazon, Etsy).
- **`WebhookProcessor`**: An Oban worker that handles asynchronous webhook processing with built-in retries.
- **`Vault`**: Manages encryption keys for secure storage of channel credentials.

### Data Flow

1.  **Update**: User updates product quantity via LiveView or a webhook receives an external change.
2.  **Persistence**: `Inventory.update_product_quantity/2` updates the database in a transaction.
3.  **Broadcast**: PubSub broadcasts `{:sync_inventory, item}` to the `"channel:#{channel_id}"` topic.
4.  **Sync**: Each `ChannelServer` receives the message, applies rate limiting, and uses the appropriate `Adapter` to update the external platform.
5.  **History**: A `SyncHistory` record is created, and telemetry events are emitted.

## 🧪 Testing & Quality

- **Run all tests**:
    ```bash
    mix test
    ```
- **Run pre-commit checks**:
    ```bash
    mix precommit
    ```
    This runs formatting, unused dependency checks, and the full test suite.

## 🚢 Deployment

The project is configured for deployment on [Fly.io](https://fly.io/) using the provided `fly.toml` and `Dockerfile`.

```bash
flyctl deploy
```
