defmodule InventorySyncWeb.ChannelLive.Index do
  use InventorySyncWeb, :live_view
  alias InventorySync.Inventory
  alias InventorySync.Workers.SyncManager
  require Logger

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Channels")
      |> stream(:channels, Inventory.list_channels())
      |> assign(:show_modal, false)
      |> assign(:form, to_form(Inventory.change_channel(%Inventory.Channel{})))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h2 class="text-2xl font-bold text-gray-800 dark:text-white">Channels</h2>
        <button
          phx-click="new-channel"
          class="btn btn-primary bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg transition-colors"
        >
          Add Channel
        </button>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          :for={{id, channel} <- @streams.channels}
          id={id}
          class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 flex flex-col justify-between hover:shadow-md transition-shadow"
        >
          <div>
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-gray-50 dark:bg-gray-700 flex items-center justify-center text-xl">
                  <%= case channel.platform do %>
                    <% :shopify -> %>
                      🛍️
                    <% :amazon -> %>
                      📦
                    <% :etsy -> %>
                      🧶
                    <% _ -> %>
                      🔌
                  <% end %>
                </div>
                <div>
                  <h3 class="font-bold text-gray-900 dark:text-white">{channel.name}</h3>
                  <p class="text-xs text-gray-500 dark:text-gray-400 capitalize">
                    {channel.platform}
                  </p>
                </div>
              </div>
              <div class={[
                "w-2 h-2 rounded-full",
                if(channel.active, do: "bg-green-500", else: "bg-gray-300")
              ]}>
              </div>
            </div>

            <div class="space-y-2 text-sm text-gray-600 dark:text-gray-300">
              <div class="flex justify-between">
                <span>Status</span>
                <span class={
                  if(channel.active, do: "text-green-600 font-medium", else: "text-gray-500")
                }>
                  {if channel.active, do: "Active", else: "Inactive"}
                </span>
              </div>
              <div class="flex justify-between">
                <span>Last Sync</span>
                <span>Just now</span>
              </div>
            </div>
          </div>

          <div class="mt-6 pt-4 border-t border-gray-100 dark:border-gray-700 flex gap-2">
            <button
              phx-click="configure"
              phx-value-id={channel.id}
              class="flex-1 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-50 dark:bg-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 rounded-lg transition-colors"
            >
              Configure
            </button>
            <button
              phx-click="sync-now"
              phx-value-id={channel.id}
              class="flex-1 py-2 text-sm font-medium text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition-colors"
            >
              Sync Now
            </button>
          </div>
        </div>
      </div>
      
    <!-- Add Channel Modal -->
      <%= if @show_modal do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl max-w-md w-full p-6 animate-in fade-in zoom-in duration-200">
            <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-4">Add New Channel</h3>

            <.form for={@form} phx-submit="save" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Channel Name
                </label>
                <.input
                  field={@form[:name]}
                  type="text"
                  class="w-full rounded-lg border-gray-300 dark:bg-gray-700 dark:border-gray-600"
                  placeholder="e.g., My Shopify Store"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Platform
                </label>
                <.input
                  field={@form[:platform]}
                  type="select"
                  options={[{"Shopify", "shopify"}, {"Amazon", "amazon"}, {"Etsy", "etsy"}]}
                  class="w-full rounded-lg border-gray-300 dark:bg-gray-700 dark:border-gray-600"
                />
              </div>
              
    <!-- Dynamic Credentials Fields (Simplified for MVP) -->
              <div class="p-4 bg-gray-50 dark:bg-gray-700/50 rounded-lg space-y-3">
                <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide">Credentials</p>

                <div>
                  <label class="block text-xs text-gray-500 mb-1">Shop URL / Seller ID</label>
                  <input
                    type="text"
                    name="credentials[shop_url]"
                    class="w-full text-sm rounded-md border-gray-300 dark:bg-gray-700 dark:border-gray-600"
                    placeholder="myshop.myshopify.com"
                  />
                </div>

                <div>
                  <label class="block text-xs text-gray-500 mb-1">Access Token / API Key</label>
                  <input
                    type="password"
                    name="credentials[access_token]"
                    class="w-full text-sm rounded-md border-gray-300 dark:bg-gray-700 dark:border-gray-600"
                    placeholder="shpat_..."
                  />
                </div>

                <div>
                  <label class="block text-xs text-gray-500 mb-1">Location ID (Shopify Only)</label>
                  <input
                    type="text"
                    name="credentials[location_id]"
                    class="w-full text-sm rounded-md border-gray-300 dark:bg-gray-700 dark:border-gray-600"
                    placeholder="12345678"
                  />
                </div>
              </div>

              <div class="flex gap-3 pt-4">
                <button
                  type="button"
                  phx-click="close-modal"
                  class="flex-1 px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="flex-1 px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg transition-colors"
                >
                  Connect Channel
                </button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("new-channel", _, socket) do
    {:noreply, assign(socket, :show_modal, true)}
  end

  def handle_event("close-modal", _, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  def handle_event("save", %{"channel" => channel_params, "credentials" => credentials}, socket) do
    # Merge credentials into channel params
    # Note: credentials come as a separate map from the form because we used raw inputs
    # We need to clean up empty values
    clean_credentials =
      credentials
      |> Enum.reject(fn {_, v} -> v == "" end)
      |> Map.new()

    params = Map.put(channel_params, "credentials", clean_credentials) |> Map.put("active", true)

    case Inventory.create_channel(params) do
      {:ok, channel} ->
        # Start the worker for this channel
        SyncManager.start_channel(channel)

        {:noreply,
         socket
         |> assign(:show_modal, false)
         |> stream_insert(:channels, channel)
         |> put_flash(:info, "Channel connected successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("sync-now", %{"id" => id}, socket) do
    channel = Inventory.get_channel!(id)
    # Simulate triggering a sync
    Logger.info("Manual sync triggered for channel #{channel.name}")
    {:noreply, put_flash(socket, :info, "Sync started for #{channel.name}")}
  end

  def handle_event("configure", _params, socket) do
    {:noreply,
     put_flash(
       socket,
       :info,
       "Configuration modal reuse not implemented yet, try deleting and re-adding."
     )}
  end
end
