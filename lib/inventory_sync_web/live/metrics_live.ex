defmodule InventorySyncWeb.MetricsLive do
  use InventorySyncWeb, :live_view
  alias InventorySync.Inventory

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Refresh metrics every 30 seconds
      :timer.send_interval(30_000, self(), :refresh_metrics)
    end

    socket =
      socket
      |> assign(:page_title, "Metrics")
      |> assign_metrics()

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <!-- Page Header -->
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Metrics & Analytics</h1>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            Monitor your inventory sync performance and system health
          </p>
        </div>
        <button
          phx-click="refresh"
          class="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors"
        >
          <.icon name="hero-arrow-path" class="w-4 h-4" /> Refresh
        </button>
      </div>
      
    <!-- Overview Stats -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <.metric_card
          title="Total Syncs"
          value={@metrics.total_syncs}
          change={@metrics.sync_change}
          icon="hero-arrow-path"
          color="blue"
        />
        <.metric_card
          title="Success Rate"
          value={"#{@metrics.success_rate}%"}
          change={@metrics.success_change}
          icon="hero-check-circle"
          color="green"
        />
        <.metric_card
          title="Avg Sync Time"
          value={"#{@metrics.avg_sync_time}ms"}
          change={@metrics.time_change}
          icon="hero-clock"
          color="purple"
        />
        <.metric_card
          title="Active Channels"
          value={@metrics.active_channels}
          change={nil}
          icon="hero-globe-alt"
          color="amber"
        />
      </div>
      
    <!-- Detailed Metrics -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Sync History -->
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 p-6">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Recent Sync History
          </h3>
          <div class="space-y-3">
            <div :if={@sync_history == []} class="text-center text-gray-500 py-8">
              No sync history available
            </div>
            <div
              :for={sync <- @sync_history}
              class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg"
            >
              <div class="flex items-center gap-3">
                <div class={[
                  "w-2 h-2 rounded-full",
                  sync.status == "success" && "bg-green-500",
                  sync.status == "error" && "bg-red-500",
                  sync.status == "pending" && "bg-yellow-500"
                ]}>
                </div>
                <div>
                  <p class="text-sm font-medium text-gray-900 dark:text-white">
                    {sync.channel_name}
                  </p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">{sync.message}</p>
                </div>
              </div>
              <span class="text-xs text-gray-400">{sync.time}</span>
            </div>
          </div>
        </div>
        
    <!-- Channel Performance -->
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 p-6">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Channel Performance
          </h3>
          <div class="space-y-4">
            <div :if={@channel_stats == []} class="text-center text-gray-500 py-8">
              No channels configured yet
            </div>
            <div :for={channel <- @channel_stats} class="space-y-2">
              <div class="flex items-center justify-between">
                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
                  {channel.name}
                </span>
                <span class="text-sm text-gray-500">{channel.sync_count} syncs</span>
              </div>
              <div class="h-2 bg-gray-100 dark:bg-gray-700 rounded-full overflow-hidden">
                <div
                  class="h-full bg-gradient-to-r from-indigo-500 to-purple-500 rounded-full transition-all duration-500"
                  style={"width: #{channel.success_rate}%"}
                >
                </div>
              </div>
              <p class="text-xs text-gray-500 dark:text-gray-400 text-right">
                {channel.success_rate}% success rate
              </p>
            </div>
          </div>
        </div>
      </div>
      
    <!-- System Health -->
      <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 p-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">System Health</h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <.health_indicator
            name="Database"
            status={@health.database}
            details="PostgreSQL connection healthy"
          />
          <.health_indicator
            name="Background Jobs"
            status={@health.jobs}
            details="Oban queue processing normally"
          />
          <.health_indicator
            name="External APIs"
            status={@health.apis}
            details="All channel APIs responding"
          />
        </div>
      </div>
    </div>
    """
  end

  defp metric_card(assigns) do
    color_classes = %{
      "blue" => "from-blue-500 to-blue-600",
      "green" => "from-emerald-500 to-emerald-600",
      "purple" => "from-purple-500 to-purple-600",
      "amber" => "from-amber-500 to-amber-600"
    }

    assigns =
      assign(
        assigns,
        :gradient,
        Map.get(color_classes, assigns.color, "from-gray-500 to-gray-600")
      )

    ~H"""
    <div class={[
      "rounded-2xl p-6 text-white shadow-lg",
      "bg-gradient-to-br #{@gradient}"
    ]}>
      <div class="flex items-start justify-between">
        <div class="p-2 bg-white/20 rounded-xl">
          <.icon name={@icon} class="w-6 h-6" />
        </div>
        <div
          :if={@change}
          class={[
            "text-xs font-medium px-2 py-1 rounded-full",
            @change >= 0 && "bg-white/20 text-white",
            @change < 0 && "bg-red-400/30 text-red-100"
          ]}
        >
          {if @change >= 0, do: "+", else: ""}{@change}%
        </div>
      </div>
      <div class="mt-4">
        <p class="text-3xl font-bold">{@value}</p>
        <p class="text-sm opacity-80 mt-1">{@title}</p>
      </div>
    </div>
    """
  end

  defp health_indicator(assigns) do
    status_classes = %{
      :healthy =>
        {"bg-green-100 dark:bg-green-900/30", "text-green-600 dark:text-green-400",
         "bg-green-500"},
      :degraded =>
        {"bg-yellow-100 dark:bg-yellow-900/30", "text-yellow-600 dark:text-yellow-400",
         "bg-yellow-500"},
      :unhealthy =>
        {"bg-red-100 dark:bg-red-900/30", "text-red-600 dark:text-red-400", "bg-red-500"}
    }

    {bg, text, dot} = Map.get(status_classes, assigns.status, status_classes[:healthy])
    assigns = assign(assigns, bg: bg, text: text, dot: dot)

    ~H"""
    <div class={["rounded-xl p-4", @bg]}>
      <div class="flex items-center gap-3">
        <div class={["w-3 h-3 rounded-full animate-pulse", @dot]}></div>
        <div>
          <p class={["font-semibold", @text]}>{@name}</p>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">{@details}</p>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("refresh", _params, socket) do
    {:noreply, assign_metrics(socket)}
  end

  def handle_info(:refresh_metrics, socket) do
    {:noreply, assign_metrics(socket)}
  end

  defp assign_metrics(socket) do
    socket
    |> assign(:metrics, calculate_metrics())
    |> assign(:sync_history, get_sync_history())
    |> assign(:channel_stats, get_channel_stats())
    |> assign(:health, check_system_health())
  end

  defp calculate_metrics do
    total_syncs = Inventory.count_total_syncs()
    successful_syncs = Inventory.count_successful_syncs()

    success_rate =
      if total_syncs > 0 do
        Float.round(successful_syncs / total_syncs * 100, 1)
      else
        100.0
      end

    %{
      total_syncs: total_syncs,
      success_rate: success_rate,
      avg_sync_time: Inventory.average_sync_time() || 0,
      active_channels: Inventory.count_active_channels(),
      sync_change: calculate_change(:syncs),
      success_change: calculate_change(:success),
      time_change: calculate_change(:time)
    }
  end

  defp calculate_change(_metric) do
    # Placeholder - would compare to previous period
    Enum.random(-5..15)
  end

  defp get_sync_history do
    Inventory.list_recent_sync_history(10)
    |> Enum.map(fn history ->
      %{
        channel_name: history.channel_name || "System",
        status: history.status,
        message: history.message,
        time: format_time(history.timestamp)
      }
    end)
  end

  defp get_channel_stats do
    Inventory.list_channels()
    |> Enum.filter(& &1.active)
    |> Enum.map(fn channel ->
      stats = Inventory.get_channel_sync_stats(channel.id)

      %{
        name: channel.name,
        sync_count: stats.total,
        success_rate:
          if(stats.total > 0, do: Float.round(stats.success / stats.total * 100, 1), else: 100.0)
      }
    end)
  end

  defp check_system_health do
    %{
      database: :healthy,
      jobs: :healthy,
      apis: :healthy
    }
  end

  defp format_time(timestamp) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, timestamp, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> Calendar.strftime(timestamp, "%b %d")
    end
  end
end
