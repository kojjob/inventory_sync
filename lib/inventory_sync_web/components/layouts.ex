defmodule InventorySyncWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use InventorySyncWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  # Helper Components

  attr :href, :string, required: true
  attr :active, :boolean, default: false
  attr :icon, :string, default: nil
  slot :inner_block, required: true

  def sidebar_link(assigns) do
    ~H"""
    <a
      href={@href}
      class={[
        if(@active,
          do: "bg-gray-50 dark:bg-gray-700 text-indigo-600 dark:text-white",
          else:
            "text-gray-700 dark:text-gray-400 hover:text-indigo-600 dark:hover:text-white hover:bg-gray-50 dark:hover:bg-gray-700"
        ),
        "group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold transition-colors"
      ]}
    >
      <%= if @icon do %>
        <.icon
          name={@icon}
          class={
            if(@active,
              do: "h-6 w-6 shrink-0 transition-colors text-indigo-600 dark:text-white",
              else:
                "h-6 w-6 shrink-0 transition-colors text-gray-400 group-hover:text-indigo-600 dark:group-hover:text-white"
            )
          }
        />
      <% end %>
      {render_slot(@inner_block)}
    </a>
    """
  end

  attr :title, :string, required: true
  attr :time, :string, required: true
  attr :message, :string, required: true
  attr :type, :string, default: "info", values: ["info", "success", "warning", "error"]

  def notification_item(assigns) do
    ~H"""
    <div class="px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors border-b border-gray-50 dark:border-gray-700 last:border-0 cursor-pointer group">
      <div class="flex justify-between items-start mb-1">
        <p class="text-sm font-medium text-gray-900 dark:text-white group-hover:text-indigo-600 transition-colors">
          {@title}
        </p>
        <span class="text-xs text-gray-400">{@time}</span>
      </div>
      <p class="text-xs text-gray-500 dark:text-gray-400 line-clamp-2">{@message}</p>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
