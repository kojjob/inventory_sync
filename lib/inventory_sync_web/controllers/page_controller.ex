defmodule InventorySyncWeb.PageController do
  use InventorySyncWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
