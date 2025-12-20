defmodule InventorySyncWeb.SettingsLive.Team do
  use InventorySyncWeb, :live_view
  alias InventorySync.Inventory
  alias InventorySync.Inventory.User

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Team Settings")
      |> stream(:users, Inventory.list_users())
      |> assign(:show_modal, false)
      |> assign(:editing_user, nil)
      |> assign(:form, to_form(Inventory.change_user(%User{})))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="border-b border-gray-200 dark:border-gray-700 pb-5">
        <h3 class="text-2xl font-bold leading-6 text-gray-900 dark:text-white">Team Settings</h3>
        <p class="mt-2 max-w-4xl text-sm text-gray-500 dark:text-gray-400">Manage team members and permissions.</p>
      </div>

      <div class="bg-white dark:bg-gray-800 shadow sm:rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <div class="sm:flex sm:items-center">
            <div class="sm:flex-auto">
              <h1 class="text-base font-semibold leading-6 text-gray-900 dark:text-white">Users</h1>
              <p class="mt-2 text-sm text-gray-700 dark:text-gray-300">A list of all the users in your account including their name, title, email and role.</p>
            </div>
            <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
              <button phx-click="add-user" class="block rounded-md bg-indigo-600 px-3 py-2 text-center text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">Add user</button>
            </div>
          </div>
          <div class="mt-8 flow-root">
            <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
              <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                <table class="min-w-full divide-y divide-gray-300 dark:divide-gray-700">
                  <thead>
                    <tr>
                      <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 dark:text-white sm:pl-0">Name</th>
                      <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 dark:text-white">Title</th>
                      <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 dark:text-white">Status</th>
                      <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 dark:text-white">Role</th>
                      <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-0">
                        <span class="sr-only">Edit</span>
                      </th>
                    </tr>
                  </thead>
                  <tbody id="users-table" phx-update="stream" class="divide-y divide-gray-200 dark:divide-gray-700">
                    <tr :for={{id, user} <- @streams.users} id={id}>
                      <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 dark:text-white sm:pl-0">
                        {user.name}
                        <div class="text-xs font-normal text-gray-500">{user.email}</div>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500 dark:text-gray-300">{user.title}</td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500 dark:text-gray-300">
                        <span class="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">{user.status}</span>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500 dark:text-gray-300">{user.role}</td>
                      <td class="whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                        <button phx-click="edit-user" phx-value-id={user.id} class="text-indigo-600 hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300">Edit</button>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Add/Edit User Modal -->
      <%= if @show_modal do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl max-w-md w-full p-6 animate-in fade-in zoom-in duration-200">
            <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-4"><%= if @editing_user, do: "Edit User", else: "Add New User" %></h3>

            <.form for={@form} phx-submit="save" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Name</label>
                <.input field={@form[:name]} type="text" class="w-full rounded-lg border-gray-300 dark:bg-gray-700 dark:border-gray-600" required />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Email</label>
                <.input field={@form[:email]} type="email" class="w-full rounded-lg border-gray-300 dark:bg-gray-700 dark:border-gray-600" required />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Title</label>
                <.input field={@form[:title]} type="text" class="w-full rounded-lg border-gray-300 dark:bg-gray-700 dark:border-gray-600" placeholder="e.g. Manager" />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Role</label>
                <.input field={@form[:role]} type="select" options={["Admin", "Editor", "Viewer"]} class="w-full rounded-lg border-gray-300 dark:bg-gray-700 dark:border-gray-600" />
              </div>

              <div class="flex gap-3 pt-4">
                <button type="button" phx-click="close-modal" class="flex-1 px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors">
                  Cancel
                </button>
                <button type="submit" class="flex-1 px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg transition-colors">
                  <%= if @editing_user, do: "Save Changes", else: "Add User" %>
                </button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("add-user", _, socket) do
    {:noreply,
     socket
     |> assign(:editing_user, nil)
     |> assign(:form, to_form(Inventory.change_user(%User{})))
     |> assign(:show_modal, true)}
  end

  def handle_event("edit-user", %{"id" => id}, socket) do
    # Fetch user for editing
    user = Inventory.get_user!(id)
    {:noreply,
     socket
     |> assign(:editing_user, user)
     |> assign(:form, to_form(Inventory.change_user(user)))
     |> assign(:show_modal, true)}
  end

  def handle_event("close-modal", _, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.editing_user, user_params)
  end

  defp save_user(socket, nil, user_params) do
    user_params = Map.put(user_params, "status", "Active")

    case Inventory.create_user(user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:show_modal, false)
         |> stream_insert(:users, user)
         |> put_flash(:info, "User created successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_user(socket, user, user_params) do
    case Inventory.update_user(user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:show_modal, false)
         |> stream_insert(:users, user)
         |> put_flash(:info, "User updated successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
