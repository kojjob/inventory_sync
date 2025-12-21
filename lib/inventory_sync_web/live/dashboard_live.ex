defmodule InventorySyncWeb.DashboardLive do
  use InventorySyncWeb, :live_view
  alias InventorySync.Inventory

  def mount(_params, _session, socket) do
    # Subscribe to PubSub for real-time updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(InventorySync.PubSub, "inventory_updates")
    end

    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign(:stats, calculate_stats())
      |> assign(:recent_activities, list_recent_activities())
      |> assign(:chart_data, Inventory.get_chart_data())

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <!-- Metrics Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <.stat_card
          title="Total Products"
          value={@stats.products}
          icon="hero-cube"
          bg_class="bg-gradient-to-br from-blue-500 to-blue-600"
          text_class="text-white"
          icon_bg="bg-white/20"
          icon_text="text-white"
        />
        <.stat_card
          title="Active Channels"
          value={@stats.channels}
          icon="hero-globe-alt"
          bg_class="bg-gradient-to-br from-emerald-500 to-emerald-600"
          text_class="text-white"
          icon_bg="bg-white/20"
          icon_text="text-white"
        />
        <.stat_card
          title="Syncs Today"
          value={@stats.syncs_today}
          icon="hero-arrow-path"
          bg_class="bg-gradient-to-br from-purple-500 to-purple-600"
          text_class="text-white"
          icon_bg="bg-white/20"
          icon_text="text-white"
        />
        <.stat_card
          title="Sync Errors"
          value={@stats.errors}
          icon="hero-exclamation-triangle"
          bg_class="bg-gradient-to-br from-rose-500 to-rose-600"
          text_class="text-white"
          icon_bg="bg-white/20"
          icon_text="text-white"
        />
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Main Chart Area -->
        <div class="lg:col-span-2 bg-white dark:bg-gray-800 rounded-3xl shadow-sm border border-gray-100 dark:border-gray-700 p-8">
          <div class="flex items-center justify-between mb-8">
            <div>
              <h3 class="text-xl font-bold text-gray-900 dark:text-white">Sync Activity</h3>
              <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">Real-time sync performance</p>
            </div>
            <select class="bg-gray-50 dark:bg-gray-700 border-none text-sm font-medium text-gray-600 dark:text-gray-300 rounded-lg py-2 px-4 focus:ring-2 focus:ring-indigo-500 cursor-pointer">
              <option>Today</option>
              <option>This Week</option>
              <option>This Month</option>
            </select>
          </div>
          
    <!-- Placeholder Chart -->
          <div class="h-80 w-full bg-white dark:bg-gray-800 rounded-2xl p-4">
            <canvas id="sync-chart" phx-hook="SyncChart" data-points={Jason.encode!(@chart_data)}>
            </canvas>
          </div>
        </div>

        <div class="lg:col-span-1 bg-white dark:bg-gray-800 rounded-3xl shadow-sm border border-gray-100 dark:border-gray-700 p-8 flex flex-col">
          <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-6">Recent Activity</h3>

          <div class="flex-1 overflow-y-auto pr-2 custom-scrollbar space-y-6">
            <div :if={@recent_activities == []} class="text-center text-gray-500 py-10">
              No activity yet.
            </div>

            <div :for={activity <- @recent_activities} class="flex gap-4">
              <div class={[
                "w-2 h-2 mt-2 rounded-full shrink-0",
                if(activity.status == "error", do: "bg-red-500", else: "bg-green-500")
              ]}>
              </div>
              <div>
                <p class="text-sm font-medium text-gray-900 dark:text-white">{activity.message}</p>
                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">{activity.time}</p>
              </div>
            </div>
          </div>

          <div class="mt-6 pt-6 border-t border-gray-100 dark:border-gray-700">
            <.link
              navigate="/activity"
              class="text-sm font-semibold text-indigo-600 dark:text-indigo-400 hover:text-indigo-500 flex items-center gap-2 group"
            >
              View all activity
              <.icon
                name="hero-arrow-right"
                class="w-4 h-4 group-hover:translate-x-1 transition-transform"
              />
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp stat_card(assigns) do
    ~H"""
    <div class={[
      "rounded-3xl p-6 transition-transform hover:-translate-y-1 duration-300 shadow-md",
      @bg_class
    ]}>
      <div class="flex items-start justify-between mb-4">
        <div class={[
          "w-12 h-12 rounded-2xl flex items-center justify-center shadow-inner",
          @icon_bg,
          @icon_text
        ]}>
          <.icon name={@icon} class="w-6 h-6" />
        </div>
        <div class="dropdown dropdown-end">
          <button class={["btn btn-ghost btn-xs btn-circle opacity-70 hover:opacity-100", @text_class]}>
            <.icon name="hero-ellipsis-horizontal" class="w-5 h-5" />
          </button>
        </div>
      </div>
      <div class={@text_class}>
        <p class="text-3xl font-bold mb-1">{@value}</p>
        <p class="text-sm font-medium opacity-90">{@title}</p>
      </div>
    </div>
    """
  end

  defp calculate_stats do
    %{
      products: Inventory.list_products() |> length(),
      channels: Inventory.list_channels() |> Enum.count(& &1.active),
      syncs_today: Inventory.count_syncs_today(),
      errors: Inventory.count_errors_today()
    }
  end

  defp list_recent_activities do
    Inventory.list_recent_sync_history(10)
    |> Enum.map(fn history ->
      %{
        message: history.message,
        time: Calendar.strftime(history.timestamp, "%H:%M:%S"),
        status: history.status
      }
    end)
  end

  # Handle PubSub messages
  def handle_info({:sync_event, history}, socket) do
    activity = %{
      message: history.message,
      time: Calendar.strftime(history.timestamp, "%H:%M:%S"),
      status: history.status
    }

    # Update stats incrementally
    new_stats =
      socket.assigns.stats
      |> Map.update!(:syncs_today, &(&1 + 1))
      |> Map.update!(:errors, fn count ->
        if(history.status == "error", do: count + 1, else: count)
      end)

    # Update Chart Data
    hour = history.timestamp.hour

    new_chart_data =
      Enum.map(socket.assigns.chart_data, fn point ->
        if point.label == "#{hour}:00" do
          Map.update!(point, :value, &(&1 + 1))
        else
          point
        end
      end)

    socket =
      socket
      |> assign(:stats, new_stats)
      |> assign(:chart_data, new_chart_data)
      |> update(:recent_activities, fn list -> [activity | list] |> Enum.take(10) end)
      |> push_event("update_chart", %{points: new_chart_data})

    {:noreply, socket}
  end

  def handle_info(_, socket), do: {:noreply, socket}
end
