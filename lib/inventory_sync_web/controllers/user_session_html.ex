defmodule InventorySyncWeb.UserSessionHTML do
  use InventorySyncWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:inventory_sync, InventorySync.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
