defmodule InventorySyncWeb.Api.V1.ChannelJSON do
  @moduledoc """
  JSON serializer for Channel resources in the API.

  Wraps channel data in a standard envelope format:
  - Single channel: `{"data": {...}}`
  - List of channels: `{"data": [...]}`

  Note: The `credentials` field is intentionally excluded from serialization
  for security reasons, as it contains sensitive API keys and secrets.
  """

  alias InventorySync.Inventory.Channel

  @doc """
  Renders a list of channels.
  """
  def index(%{channels: channels}) do
    %{data: for(channel <- channels, do: data(channel))}
  end

  @doc """
  Renders a single channel.
  """
  def show(%{channel: channel}) do
    %{data: data(channel)}
  end

  @doc """
  Serializes a channel to a JSON-compatible map.

  Excludes the `credentials` field to prevent exposure of sensitive data.
  """
  def data(%Channel{} = channel) do
    %{
      id: channel.id,
      name: channel.name,
      platform: channel.platform,
      active: channel.active,
      inserted_at: channel.inserted_at,
      updated_at: channel.updated_at
    }
  end
end
