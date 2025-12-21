defmodule InventorySync.Workers.ChannelServer do
  @moduledoc """
  GenServer that manages a specific channel's inventory sync.
  It handles rate limiting, authentication, and pushing updates.
  """
  use GenServer
  require Logger

  alias InventorySync.Inventory.Channel
  alias InventorySync.Inventory

  # Client API

  def start_link(%Channel{} = channel) do
    GenServer.start_link(__MODULE__, channel, name: via_tuple(channel.id))
  end

  def update_inventory(channel_id, item, quantity) do
    GenServer.call(via_tuple(channel_id), {:update_inventory, item, quantity})
  end

  def via_tuple(channel_id) do
    {:via, Registry, {InventorySync.ChannelRegistry, channel_id}}
  end

  # Server Callbacks

  @impl true
  def init(%Channel{} = channel) do
    Logger.info("Starting ChannelServer for #{channel.name} (#{channel.platform})")
    Phoenix.PubSub.subscribe(InventorySync.PubSub, "channel:#{channel.id}")

    # Initialize state with a simple token bucket for rate limiting
    # Allow 2 requests per second (Shopify allows 2/s leak rate, bucket size 40)
    # We'll be conservative for now.
    {:ok,
     %{
       channel: channel,
       adapter: adapter_for(channel.platform),
       last_request_time: 0,
       # Initial tokens
       tokens: 2.0,
       max_tokens: 2.0,
       # Tokens per second
       refill_rate: 2.0,
       last_refill: System.monotonic_time(:millisecond)
     }}
  end

  @impl true
  # Handle messages without retry count (for backward compatibility)
  def handle_info({:sync_inventory, item}, state) do
    handle_info({:sync_inventory, item, 0}, state)
  end

  @impl true
  def handle_info({:sync_inventory, item, retry_count}, state) do
    start_time = System.monotonic_time()

    Logger.info(
      "Received sync_inventory for #{state.channel.name}: SKU #{item.platform_sku} -> #{item.quantity} (attempt #{retry_count + 1})"
    )

    # Check rate limit
    {new_tokens, can_proceed} = check_rate_limit(state)

    if can_proceed do
      case state.adapter.update_inventory(
             decode_credentials(state.channel.credentials),
             item,
             item.quantity
           ) do
        {:ok, _result} ->
          :telemetry.execute(
            [:inventory_sync, :worker, :sync_success],
            %{duration: System.monotonic_time() - start_time},
            %{channel: state.channel.platform, sku: item.platform_sku, retry_count: retry_count}
          )

          # Record History
          {:ok, history} =
            Inventory.create_sync_history(%{
              sku: item.platform_sku,
              channel_name: state.channel.name,
              status: "success",
              message: "Successfully updated quantity to #{item.quantity}",
              timestamp: DateTime.utc_now()
            })

          # Broadcast for UI
          Phoenix.PubSub.broadcast(
            InventorySync.PubSub,
            "inventory_updates",
            {:sync_event, history}
          )

          Logger.info("Successfully synced SKU #{item.platform_sku} to #{state.channel.name}")

        {:error, reason} ->
          :telemetry.execute(
            [:inventory_sync, :worker, :sync_failure],
            %{duration: System.monotonic_time() - start_time},
            %{
              channel: state.channel.platform,
              sku: item.platform_sku,
              reason: inspect(reason),
              retry_count: retry_count
            }
          )

          # Determine if error is retryable
          should_retry = retryable_error?(reason) and retry_count < max_retries()

          if should_retry do
            # Calculate exponential backoff delay (2^n seconds, capped at 5 minutes)
            delay_ms = calculate_backoff_delay(retry_count)

            Logger.warning(
              "Failed to sync SKU #{item.platform_sku} to #{state.channel.name}: #{inspect(reason)}. Retrying in #{delay_ms}ms (attempt #{retry_count + 2}/#{max_retries() + 1})"
            )

            # Schedule retry with incremented retry count
            Process.send_after(self(), {:sync_inventory, item, retry_count + 1}, delay_ms)

            # Record temporary failure history
            Inventory.create_sync_history(%{
              sku: item.platform_sku,
              channel_name: state.channel.name,
              status: "retrying",
              message:
                "Failed (attempt #{retry_count + 1}): #{inspect(reason)}. Retrying in #{delay_ms}ms",
              timestamp: DateTime.utc_now()
            })
          else
            # Permanent failure or max retries reached
            failure_reason =
              if retry_count >= max_retries() do
                "Max retries (#{max_retries()}) exceeded: #{inspect(reason)}"
              else
                "Permanent failure: #{inspect(reason)}"
              end

            Logger.error(
              "Permanently failed to sync SKU #{item.platform_sku} to #{state.channel.name}: #{failure_reason}"
            )

            # Record permanent failure history
            Inventory.create_sync_history(%{
              sku: item.platform_sku,
              channel_name: state.channel.name,
              status: "failed",
              message: failure_reason,
              timestamp: DateTime.utc_now()
            })

            # Broadcast permanent failure
            Phoenix.PubSub.broadcast(
              InventorySync.PubSub,
              "inventory_updates",
              {:sync_event,
               %{
                 sku: item.platform_sku,
                 channel_name: state.channel.name,
                 status: "failed",
                 message: failure_reason,
                 timestamp: DateTime.utc_now()
               }}
            )
          end
      end

      {:noreply, %{state | tokens: new_tokens, last_refill: System.monotonic_time(:millisecond)}}
    else
      :telemetry.execute(
        [:inventory_sync, :worker, :rate_limited],
        %{count: 1},
        %{channel: state.channel.platform}
      )

      Logger.warning(
        "Rate limit exceeded for #{state.channel.name}. Re-queueing SKU #{item.platform_sku}"
      )

      # Rate limiting doesn't consume a retry attempt - just re-queue with same retry count
      Process.send_after(self(), {:sync_inventory, item, retry_count}, 1000)
      {:noreply, %{state | tokens: new_tokens, last_refill: System.monotonic_time(:millisecond)}}
    end
  end

  defp check_rate_limit(state) do
    now = System.monotonic_time(:millisecond)
    time_passed = (now - state.last_refill) / 1000.0

    # Refill tokens
    tokens = min(state.max_tokens, state.tokens + time_passed * state.refill_rate)

    if tokens >= 1.0 do
      {tokens - 1.0, true}
    else
      {tokens, false}
    end
  end

  @impl true
  def handle_call({:update_inventory, item, quantity}, _from, state) do
    Logger.info(
      "Updating inventory for #{state.channel.name}: SKU #{item.platform_sku} -> #{quantity}"
    )

    result =
      state.adapter.update_inventory(
        decode_credentials(state.channel.credentials),
        item,
        quantity
      )

    # In a real implementation, we would handle rate limiting and retries here

    {:reply, result, state}
  end

  # Retry Logic Helpers

  @max_retries 5
  defp max_retries, do: @max_retries

  # Calculate exponential backoff delay in milliseconds.
  # Formula: 2^retry_count * 1000ms, capped at 5 minutes (300,000ms)
  #
  # Examples:
  # - retry 0: 1 second
  # - retry 1: 2 seconds
  # - retry 2: 4 seconds
  # - retry 3: 8 seconds
  # - retry 4: 16 seconds
  # - retry 5+: 32 seconds (capped at 5 minutes)
  defp calculate_backoff_delay(retry_count) do
    # 2^retry_count * 1000, capped at 5 minutes
    delay = :math.pow(2, retry_count) * 1000
    min(delay, 300_000) |> trunc()
  end

  # Determine if an error is retryable.
  #
  # Retryable errors:
  # - Network errors (timeout, connection refused, etc.)
  # - Server errors (5xx status codes)
  # - Rate limiting (429 status code)
  #
  # Non-retryable errors (permanent failures):
  # - Authentication errors (401, 403)
  # - Not found (404)
  # - Bad request (400)
  # - Other client errors (4xx except 429)
  defp retryable_error?(reason) do
    case reason do
      # HTTP status code errors
      # Server errors
      {:http_error, status, _} when status >= 500 -> true
      # Rate limiting
      {:http_error, 429, _} -> true
      # Client errors (permanent)
      {:http_error, status, _} when status >= 400 and status < 500 -> false
      # Network errors (all retryable)
      :timeout -> true
      :econnrefused -> true
      :nxdomain -> true
      {:error, :timeout} -> true
      {:error, :econnrefused} -> true
      {:error, :nxdomain} -> true
      # Default: retry on unknown errors (safer to retry than to give up)
      _ -> true
    end
  end

  defp adapter_for(platform) do
    if Application.get_env(:inventory_sync, :use_mock_adapter) do
      InventorySync.Integrations.MockAdapter
    else
      case platform do
        :shopify -> InventorySync.Integrations.ShopifyAdapter
        :amazon -> InventorySync.Integrations.AmazonAdapter
        :etsy -> InventorySync.Integrations.EtsyAdapter
        _ -> InventorySync.Integrations.MockAdapter
      end
    end
  end

  # Decode credentials from JSON string to map for adapter consumption
  defp decode_credentials(nil), do: %{}
  defp decode_credentials(credentials) when is_map(credentials), do: credentials

  defp decode_credentials(credentials) when is_binary(credentials) do
    case Jason.decode(credentials) do
      {:ok, decoded} -> decoded
      {:error, _} -> %{}
    end
  end
end
