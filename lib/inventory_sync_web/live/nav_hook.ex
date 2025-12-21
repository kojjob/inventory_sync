defmodule InventorySyncWeb.NavHook do
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    {:cont, attach_hook(socket, :set_current_path, :handle_params, &handle_params/3)}
  end

  defp handle_params(_params, url, socket) do
    {:cont, assign(socket, :current_path, URI.parse(url).path)}
  end
end
