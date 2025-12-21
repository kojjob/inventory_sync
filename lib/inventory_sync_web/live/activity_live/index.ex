defmodule InventorySyncWeb.ActivityLive.Index do
  use InventorySyncWeb, :live_view
  alias InventorySync.Inventory

  def mount(_params, _session, socket) do
    # Subscribe to updates
    if connected?(socket), do: Phoenix.PubSub.subscribe(InventorySync.PubSub, "inventory_updates")

    socket =
      socket
      |> assign(:page_title, "Activity Log")
      |> stream(:activities, Inventory.list_recent_sync_history(50))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="border-b border-gray-200 dark:border-gray-700 pb-5">
        <h3 class="text-2xl font-bold leading-6 text-gray-900 dark:text-white">Activity Log</h3>
        <p class="mt-2 max-w-4xl text-sm text-gray-500 dark:text-gray-400">
          View all recent sync events and system activities.
        </p>
      </div>

      <div class="bg-white dark:bg-gray-800 shadow sm:rounded-lg overflow-hidden">
        <ul
          role="list"
          class="divide-y divide-gray-200 dark:divide-gray-700"
          id="activity-list"
          phx-update="stream"
        >
          <li
            :for={{id, activity} <- @streams.activities}
            id={id}
            class="p-4 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
          >
            <div class="flex space-x-3">
              <div class="flex-shrink-0">
                <%= if activity.status == "success" do %>
                  <div class="h-8 w-8 rounded-full bg-green-100 dark:bg-green-900 flex items-center justify-center">
                    <.icon name="hero-check" class="h-5 w-5 text-green-600 dark:text-green-300" />
                  </div>
                <% else %>
                  <div class="h-8 w-8 rounded-full bg-red-100 dark:bg-red-900 flex items-center justify-center">
                    <.icon
                      name="hero-exclamation-triangle"
                      class="h-5 w-5 text-red-600 dark:text-red-300"
                    />
                  </div>
                <% end %>
              </div>
              <div class="flex-1 space-y-1">
                <div class="flex items-center justify-between">
                  <h3 class="text-sm font-medium text-gray-900 dark:text-white capitalize">
                    {activity.channel_name} Sync
                  </h3>
                  <p class="text-sm text-gray-500 dark:text-gray-400">
                    {Calendar.strftime(activity.timestamp, "%Y-%m-%d %H:%M:%S")}
                  </p>
                </div>
                <p class="text-sm text-gray-500 dark:text-gray-400">{activity.message}</p>
                <div class="flex items-center gap-2">
                  <span class="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 text-xs font-medium text-gray-600 ring-1 ring-inset ring-gray-500/10 dark:bg-gray-400/10 dark:text-gray-400 dark:ring-gray-400/20">
                    SKU: {activity.sku}
                  </span>
                </div>
              </div>
            </div>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  def handle_info({:sync_event, activity}, socket) do
    {:noreply, stream_insert(socket, :activities, activity, at: 0)}
  end
end
