defmodule InventorySyncWeb.ProductLive.Show do
  use InventorySyncWeb, :live_view

  alias InventorySync.Inventory

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    product = Inventory.get_product!(id)
    inventory_items = Inventory.list_inventory_items_for_product(id)
    channels = Inventory.list_channels()

    socket =
      socket
      |> assign(:page_title, "Product: #{product.name}")
      |> assign(:product, product)
      |> assign(:inventory_items, inventory_items)
      |> assign(:available_channels, channels)
      |> assign(:show_add_mapping_modal, false)
      |> assign(:editing_item_id, nil)
      |> assign(:form, to_form(%{}))

    {:ok, socket}
  end

  @impl true
  def handle_event("show-add-mapping", _params, socket) do
    # Get channels that don't have a mapping yet
    mapped_channel_ids = Enum.map(socket.assigns.inventory_items, & &1.channel_id)
    available = Enum.filter(socket.assigns.available_channels, &(&1.id not in mapped_channel_ids))

    socket =
      socket
      |> assign(:show_add_mapping_modal, true)
      |> assign(:unmapped_channels, available)
      |> assign(:form, to_form(%{"platform_sku" => "", "quantity" => "0"}))

    {:noreply, socket}
  end

  @impl true
  def handle_event("hide-add-mapping", _params, socket) do
    {:noreply, assign(socket, :show_add_mapping_modal, false)}
  end

  @impl true
  def handle_event(
        "add-mapping",
        %{"channel_id" => channel_id, "platform_sku" => platform_sku, "quantity" => quantity},
        socket
      ) do
    attrs = %{
      product_id: socket.assigns.product.id,
      channel_id: String.to_integer(channel_id),
      platform_sku: platform_sku,
      quantity: String.to_integer(quantity),
      external_id: "manual_#{:erlang.system_time(:millisecond)}"
    }

    case Inventory.create_inventory_item(attrs) do
      {:ok, _inventory_item} ->
        inventory_items = Inventory.list_inventory_items_for_product(socket.assigns.product.id)

        socket =
          socket
          |> assign(:inventory_items, inventory_items)
          |> assign(:show_add_mapping_modal, false)
          |> put_flash(:info, "Channel mapping added successfully")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("edit-mapping", %{"id" => id}, socket) do
    {:noreply, assign(socket, :editing_item_id, String.to_integer(id))}
  end

  @impl true
  def handle_event("cancel-edit", _params, socket) do
    {:noreply, assign(socket, :editing_item_id, nil)}
  end

  @impl true
  def handle_event("save-mapping", params, socket) do
    id = String.to_integer(params["item_id"])
    inventory_item = Enum.find(socket.assigns.inventory_items, &(&1.id == id))

    case Inventory.update_inventory_item(inventory_item, %{
           platform_sku: params["platform_sku"],
           quantity: String.to_integer(params["quantity"])
         }) do
      {:ok, _} ->
        inventory_items = Inventory.list_inventory_items_for_product(socket.assigns.product.id)

        socket =
          socket
          |> assign(:inventory_items, inventory_items)
          |> assign(:editing_item_id, nil)
          |> put_flash(:info, "Mapping updated successfully")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update mapping")}
    end
  end

  @impl true
  def handle_event("delete-mapping", %{"id" => id}, socket) do
    inventory_item = Enum.find(socket.assigns.inventory_items, &(&1.id == String.to_integer(id)))

    case Inventory.delete_inventory_item(inventory_item) do
      {:ok, _} ->
        inventory_items = Inventory.list_inventory_items_for_product(socket.assigns.product.id)

        socket =
          socket
          |> assign(:inventory_items, inventory_items)
          |> put_flash(:info, "Channel mapping removed")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove mapping")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="mb-8 border-b border-gray-200 dark:border-gray-700 pb-5">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold leading-7 text-gray-900 dark:text-white sm:text-3xl sm:tracking-tight">
              {@product.name}
            </h1>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
              SKU: {@product.sku} • Total Quantity: {@product.total_quantity}
            </p>
          </div>
          <div class="flex gap-3">
            <.link
              navigate="/products"
              class="inline-flex items-center rounded-md bg-white dark:bg-gray-800 px-3 py-2 text-sm font-semibold text-gray-900 dark:text-gray-100 shadow-sm ring-1 ring-inset ring-gray-300 dark:ring-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700"
            >
              Back to Products
            </.link>
            <button
              type="button"
              phx-click="show-add-mapping"
              class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            >
              <.icon name="hero-plus" class="h-5 w-5 mr-1" /> Add Channel Mapping
            </button>
          </div>
        </div>
      </div>

      <div class="bg-white dark:bg-gray-800 shadow-sm ring-1 ring-gray-900/5 dark:ring-gray-100/5 sm:rounded-xl">
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-base font-semibold leading-6 text-gray-900 dark:text-white mb-4">
            Channel Mappings
          </h3>

          <%= if Enum.empty?(@inventory_items) do %>
            <div class="text-center py-12">
              <.icon name="hero-cube-transparent" class="mx-auto h-12 w-12 text-gray-400" />
              <h3 class="mt-2 text-sm font-semibold text-gray-900 dark:text-white">
                No channel mappings
              </h3>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Get started by adding a channel mapping for this product.
              </p>
            </div>
          <% else %>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-300 dark:divide-gray-700">
                <thead>
                  <tr>
                    <th
                      scope="col"
                      class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 dark:text-white sm:pl-0"
                    >
                      Channel
                    </th>
                    <th
                      scope="col"
                      class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 dark:text-white"
                    >
                      Platform SKU
                    </th>
                    <th
                      scope="col"
                      class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 dark:text-white"
                    >
                      Quantity
                    </th>
                    <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-0">
                      <span class="sr-only">Actions</span>
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                  <%= for item <- @inventory_items do %>
                    <tr>
                      <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 dark:text-white sm:pl-0">
                        <div class="flex items-center">
                          <.icon name="hero-globe-alt" class="h-5 w-5 text-gray-400 mr-2" />
                          {item.channel.name}
                        </div>
                      </td>
                      <%= if @editing_item_id == item.id do %>
                        <td
                          class="whitespace-nowrap px-3 py-4 text-sm text-gray-500 dark:text-gray-300"
                          colspan="2"
                        >
                          <form
                            phx-submit="save-mapping"
                            phx-click-away="cancel-edit"
                            class="flex items-center gap-2"
                          >
                            <input type="hidden" name="item_id" value={item.id} />
                            <input
                              type="text"
                              name="platform_sku"
                              value={item.platform_sku}
                              placeholder="Platform SKU"
                              class="block w-full rounded-md border-0 py-1 text-gray-900 dark:text-white dark:bg-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 dark:ring-gray-700"
                            />
                            <input
                              type="number"
                              name="quantity"
                              value={item.quantity}
                              class="block w-24 rounded-md border-0 py-1 text-gray-900 dark:text-white dark:bg-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 dark:ring-gray-700"
                            />
                            <button
                              type="submit"
                              class="text-green-600 hover:text-green-900 whitespace-nowrap"
                            >
                              Save
                            </button>
                          </form>
                        </td>
                        <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                          <button
                            type="button"
                            phx-click="cancel-edit"
                            class="text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-300"
                          >
                            Cancel
                          </button>
                        </td>
                      <% else %>
                        <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500 dark:text-gray-300">
                          {item.platform_sku}
                        </td>
                        <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500 dark:text-gray-300">
                          {item.quantity}
                        </td>
                        <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                          <button
                            type="button"
                            phx-click="edit-mapping"
                            phx-value-id={item.id}
                            class="text-indigo-600 hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300 mr-4"
                          >
                            Edit
                          </button>
                          <button
                            type="button"
                            phx-click="delete-mapping"
                            phx-value-id={item.id}
                            data-confirm="Are you sure?"
                            class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300"
                          >
                            Remove
                          </button>
                        </td>
                      <% end %>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </div>

      <%= if @show_add_mapping_modal do %>
        <div class="relative z-10" role="dialog" aria-modal="true">
          <div class="fixed inset-0 bg-gray-500 bg-opacity-75"></div>
          <div class="fixed inset-0 z-10 w-screen overflow-y-auto">
            <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
              <div class="relative transform overflow-hidden rounded-lg bg-white dark:bg-gray-800 px-4 pb-4 pt-5 text-left shadow-xl sm:my-8 sm:w-full sm:max-w-lg sm:p-6">
                <div class="mt-3 text-center sm:mt-5">
                  <h3 class="text-base font-semibold leading-6 text-gray-900 dark:text-white">
                    Add Channel Mapping
                  </h3>
                  <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
                    Link this product to a sales channel
                  </p>
                </div>

                <.form for={@form} phx-submit="add-mapping" class="mt-5 sm:mt-6 space-y-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-900 dark:text-white">
                      Channel
                    </label>
                    <select
                      name="channel_id"
                      required
                      class="mt-2 block w-full rounded-md border-0 py-1.5 text-gray-900 dark:text-white dark:bg-gray-900 ring-1 ring-inset ring-gray-300 dark:ring-gray-700 sm:text-sm"
                    >
                      <option value="">Select channel...</option>
                      <%= for channel <- @unmapped_channels do %>
                        <option value={channel.id}>{channel.name}</option>
                      <% end %>
                    </select>
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-900 dark:text-white">
                      Platform SKU
                    </label>
                    <input
                      type="text"
                      name="platform_sku"
                      required
                      placeholder="e.g., SHOP-12345"
                      class="mt-2 block w-full rounded-md border-0 py-1.5 text-gray-900 dark:text-white dark:bg-gray-900 ring-1 ring-inset ring-gray-300 dark:ring-gray-700 sm:text-sm"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-900 dark:text-white">
                      Quantity
                    </label>
                    <input
                      type="number"
                      name="quantity"
                      required
                      min="0"
                      value="0"
                      class="mt-2 block w-full rounded-md border-0 py-1.5 text-gray-900 dark:text-white dark:bg-gray-900 ring-1 ring-inset ring-gray-300 dark:ring-gray-700 sm:text-sm"
                    />
                  </div>

                  <div class="mt-5 sm:grid sm:grid-flow-row-dense sm:grid-cols-2 sm:gap-3">
                    <button
                      type="submit"
                      class="inline-flex w-full justify-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white hover:bg-indigo-500 sm:col-start-2"
                    >
                      Add Mapping
                    </button>
                    <button
                      type="button"
                      phx-click="hide-add-mapping"
                      class="mt-3 inline-flex w-full justify-center rounded-md bg-white dark:bg-gray-700 px-3 py-2 text-sm font-semibold text-gray-900 dark:text-white ring-1 ring-inset ring-gray-300 dark:ring-gray-600 sm:col-start-1 sm:mt-0"
                    >
                      Cancel
                    </button>
                  </div>
                </.form>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
