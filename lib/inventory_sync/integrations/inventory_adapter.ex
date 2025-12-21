defmodule InventorySync.Integrations.InventoryAdapter do
  @moduledoc """
  Behaviour for inventory channel integrations.
  """

  @callback update_inventory(credentials :: map(), item :: map(), quantity :: integer()) ::
              {:ok, any()} | {:error, any()}

  @callback fetch_inventory(credentials :: map(), item :: map()) ::
              {:ok, integer()} | {:error, any()}
end
