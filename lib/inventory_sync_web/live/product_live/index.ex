defmodule InventorySyncWeb.ProductLive.Index do
  use InventorySyncWeb, :live_view
  alias InventorySync.Inventory

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Products")
      |> stream(:products, Inventory.list_products())
      |> assign(:editing_product, nil)
      |> assign(:show_modal, false)
      |> assign(:form, to_form(Inventory.change_product(%Inventory.Product{})))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-800 shadow sm:rounded-lg">
      <div class="px-4 py-5 sm:p-6">
        <div class="sm:flex sm:items-center">
          <div class="sm:flex-auto">
            <h1 class="text-base font-semibold leading-6 text-gray-900 dark:text-white">Products</h1>
            <p class="mt-2 text-sm text-gray-700 dark:text-gray-300">
              A list of all the products in your account including their name, sku and total quantity.
            </p>
          </div>
          <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
            <button
              phx-click="add-product"
              class="block rounded-md bg-indigo-600 px-3 py-2 text-center text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            >
              Add Product
            </button>
          </div>
        </div>
        <div class="mt-8 flow-root">
          <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
            <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
              <table class="min-w-full divide-y divide-gray-300 dark:divide-gray-700">
                <thead>
                  <tr>
                    <th
                      scope="col"
                      class="py-3.5 pl-4 pr-3 text-left text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider sm:pl-0"
                    >
                      SKU
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-4 text-left text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                    >
                      Name
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-4 text-left text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                    >
                      Total Quantity
                    </th>
                    <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-0">
                      <span class="sr-only">Edit</span>
                    </th>
                  </tr>
                </thead>
                <tbody
                  id="products-table"
                  phx-update="stream"
                  class="divide-y divide-gray-200 dark:divide-gray-700"
                >
                  <tr :for={{id, product} <- @streams.products} id={id}>
                    <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 dark:text-white sm:pl-0">
                      {product.sku}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">
                      {product.name}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">
                      <%= if @editing_product == product.id do %>
                        <form
                          phx-submit="save-quantity"
                          phx-click-away="cancel-edit"
                          class="flex items-center gap-2"
                        >
                          <input type="hidden" name="product_id" value={product.id} />
                          <input
                            type="number"
                            name="quantity"
                            value={product.total_quantity}
                            required
                            class="w-20 rounded border-gray-300 text-sm"
                            autofocus
                          />
                          <button type="submit" class="text-green-600 hover:text-green-900">
                            Save
                          </button>
                        </form>
                      <% else %>
                        <div
                          class="flex items-center gap-2 group cursor-pointer"
                          phx-click="edit-quantity"
                          phx-value-id={product.id}
                        >
                          {product.total_quantity}
                          <.icon
                            name="hero-pencil"
                            class="w-4 h-4 text-gray-400 opacity-0 group-hover:opacity-100 transition-opacity"
                          />
                        </div>
                      <% end %>
                    </td>
                    <td class="whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                      <.link
                        navigate={~p"/products/#{product.id}"}
                        class="text-indigo-600 hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300"
                      >
                        Manage Mappings
                      </.link>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Add Product Modal -->
    <%= if @show_modal do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl max-w-md w-full p-6 animate-in fade-in zoom-in duration-200">
          <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-4">Add New Product</h3>

          <.form for={@form} phx-submit="save-product" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                SKU
              </label>
              <.input
                field={@form[:sku]}
                type="text"
                class="w-full rounded-lg border-gray-300 dark:bg-gray-700 dark:border-gray-600"
                required
                placeholder="e.g. SKU-123"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Name
              </label>
              <.input
                field={@form[:name]}
                type="text"
                class="w-full rounded-lg border-gray-300 dark:bg-gray-700 dark:border-gray-600"
                required
                placeholder="Product Name"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Initial Quantity
              </label>
              <.input
                field={@form[:total_quantity]}
                type="number"
                class="w-full rounded-lg border-gray-300 dark:bg-gray-700 dark:border-gray-600"
                required
                value="0"
              />
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
                Add Product
              </button>
            </div>
          </.form>
        </div>
      </div>
    <% end %>
    """
  end

  def handle_event("add-product", _, socket) do
    {:noreply, assign(socket, :show_modal, true)}
  end

  def handle_event("close-modal", _, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  def handle_event("save-product", %{"product" => product_params}, socket) do
    case Inventory.create_product(product_params) do
      {:ok, product} ->
        {:noreply,
         socket
         |> assign(:show_modal, false)
         |> stream_insert(:products, product)
         |> put_flash(:info, "Product created successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("edit-quantity", %{"id" => id}, socket) do
    product_id = String.to_integer(id)
    product = Inventory.get_product!(product_id)

    socket =
      socket
      |> assign(:editing_product, product_id)
      |> stream_insert(:products, product)

    {:noreply, socket}
  end

  def handle_event("cancel-edit", _, socket) do
    # Re-insert the product being edited to re-render the row without edit mode
    socket =
      case socket.assigns.editing_product do
        nil ->
          socket

        product_id ->
          product = Inventory.get_product!(product_id)

          socket
          |> assign(:editing_product, nil)
          |> stream_insert(:products, product)
      end

    {:noreply, socket}
  end

  def handle_event("save-quantity", %{"product_id" => id, "quantity" => quantity}, socket) do
    case Integer.parse(quantity) do
      {qty, ""} ->
        id = String.to_integer(id)

        case Inventory.update_product_quantity(id, qty) do
          {:ok, product} ->
            {:noreply,
             socket
             |> assign(:editing_product, nil)
             |> stream_insert(:products, product)
             |> put_flash(:info, "Quantity updated successfully")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to update quantity")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "Invalid quantity")}
    end
  end
end
