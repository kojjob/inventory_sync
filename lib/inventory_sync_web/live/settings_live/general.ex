defmodule InventorySyncWeb.SettingsLive.General do
  use InventorySyncWeb, :live_view
  alias InventorySync.Inventory

  def mount(_params, _session, socket) do
    company_name = Inventory.get_setting("company_name", "")
    {:ok, assign(socket, page_title: "General Settings", company_name: company_name)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="border-b border-gray-200 dark:border-gray-700 pb-5">
        <h3 class="text-2xl font-bold leading-6 text-gray-900 dark:text-white">General Settings</h3>
        <p class="mt-2 max-w-4xl text-sm text-gray-500 dark:text-gray-400">
          Manage your application preferences and configurations.
        </p>
      </div>

      <div class="bg-white dark:bg-gray-800 shadow sm:rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-base font-semibold leading-6 text-gray-900 dark:text-white">
            Application Profile
          </h3>
          <div class="mt-2 max-w-xl text-sm text-gray-500 dark:text-gray-400">
            <p>Update your company details and contact information.</p>
          </div>
          <form phx-submit="save" class="mt-5 space-y-4">
            <div>
              <label
                for="company-name"
                class="block text-sm font-medium leading-6 text-gray-900 dark:text-gray-100"
              >
                Company Name
              </label>
              <div class="mt-2">
                <input
                  type="text"
                  name="company_name"
                  id="company-name"
                  value={@company_name}
                  required
                  class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 dark:bg-gray-700 dark:text-white dark:ring-gray-600"
                  placeholder="Acme Corp"
                />
              </div>
            </div>
            <button
              type="submit"
              class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            >
              Save
            </button>
          </form>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("save", %{"company_name" => name}, socket) do
    case Inventory.put_setting("company_name", name) do
      {:ok, _setting} ->
        {:noreply,
         socket
         |> assign(:company_name, name)
         |> put_flash(:info, "Settings saved successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Company name cannot be empty.")}
    end
  end
end
