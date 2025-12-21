defmodule InventorySync.Workers.SyncManager do
  @moduledoc """
  DynamicSupervisor to manage ChannelServer processes.
  """
  use DynamicSupervisor

  alias InventorySync.Workers.ChannelServer

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_channel(channel) do
    DynamicSupervisor.start_child(__MODULE__, {ChannelServer, channel})
  end
end
