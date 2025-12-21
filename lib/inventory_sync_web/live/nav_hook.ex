defmodule InventorySyncWeb.NavHook do
  @moduledoc """
  LiveView hook that assigns current_scope and current_path to the socket.

  This hook is used by live_session to ensure authenticated LiveViews
  have access to the current user scope and navigation path.
  """
  import Phoenix.LiveView
  import Phoenix.Component

  alias InventorySync.Accounts
  alias InventorySync.Accounts.Scope

  def on_mount(:default, _params, session, socket) do
    socket =
      socket
      |> assign_current_scope(session)
      |> attach_hook(:set_current_path, :handle_params, &handle_params/3)

    {:cont, socket}
  end

  defp assign_current_scope(socket, session) do
    case session do
      %{"user_token" => user_token} ->
        case Accounts.get_user_by_session_token(user_token) do
          {user, _token_inserted_at} ->
            assign(socket, :current_scope, Scope.for_user(user))

          nil ->
            assign(socket, :current_scope, nil)
        end

      _ ->
        assign(socket, :current_scope, nil)
    end
  end

  defp handle_params(_params, url, socket) do
    {:cont, assign(socket, :current_path, URI.parse(url).path)}
  end
end
