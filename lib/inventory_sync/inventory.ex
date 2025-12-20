defmodule InventorySync.Inventory do
  @moduledoc """
  The Inventory context.
  """

  import Ecto.Query, warn: false
  alias InventorySync.Repo
  alias InventorySync.Audit
  alias InventorySync.Accounts.User

  alias InventorySync.Inventory.Channel

  @doc """
  Returns the list of channels.

  ## Examples

      iex> list_channels()
      [%Channel{}, ...]

  """
  def list_channels do
    Repo.all(Channel)
  end

  @doc """
  Gets a single channel.

  Raises `Ecto.NoResultsError` if the Channel does not exist.

  ## Examples

      iex> get_channel!(123)
      %Channel{}

      iex> get_channel!(456)
      ** (Ecto.NoResultsError)

  """
  def get_channel!(id), do: Repo.get!(Channel, id)

  @doc """
  Creates a channel.

  ## Examples

      iex> create_channel(%{field: value})
      {:ok, %Channel{}}

      iex> create_channel(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_channel(attrs) do
    %Channel{}
    |> Channel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a channel.

  ## Examples

      iex> update_channel(channel, %{field: new_value})
      {:ok, %Channel{}}

      iex> update_channel(channel, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_channel(%Channel{} = channel, attrs) do
    channel
    |> Channel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a channel.

  ## Examples

      iex> delete_channel(channel)
      {:ok, %Channel{}}

      iex> delete_channel(channel)
      {:error, %Ecto.Changeset{}}

  """
  def delete_channel(%Channel{} = channel) do
    Repo.delete(channel)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking channel changes.

  ## Examples

      iex> change_channel(channel)
      %Ecto.Changeset{data: %Channel{}}

  """
  def change_channel(%Channel{} = channel, attrs \\ %{}) do
    Channel.changeset(channel, attrs)
  end

  # ============================================================================
  # Audit-aware Channel Operations
  # ============================================================================

  @doc """
  Creates a channel and logs the action to the audit trail.

  ## Examples

      iex> create_channel_with_audit(%{field: value}, user)
      {:ok, %Channel{}}

  """
  def create_channel_with_audit(attrs, %User{} = user) do
    case create_channel(attrs) do
      {:ok, channel} ->
        changes = Audit.calculate_changes(nil, Map.take(attrs, [:name, :platform]))
        Audit.log_action(user, "created", channel, changes)
        {:ok, channel}

      error ->
        error
    end
  end

  @doc """
  Updates a channel and logs the action to the audit trail.

  ## Examples

      iex> update_channel_with_audit(channel, %{field: new_value}, user)
      {:ok, %Channel{}}

  """
  def update_channel_with_audit(%Channel{} = channel, attrs, %User{} = user) do
    old_attrs = Map.take(channel, [:name, :platform, :active])

    case update_channel(channel, attrs) do
      {:ok, updated_channel} ->
        new_attrs = Map.take(updated_channel, [:name, :platform, :active])
        changes = Audit.calculate_changes(old_attrs, new_attrs)

        unless changes == %{} do
          Audit.log_action(user, "updated", updated_channel, changes)
        end

        {:ok, updated_channel}

      error ->
        error
    end
  end

  @doc """
  Deletes a channel and logs the action to the audit trail.

  ## Examples

      iex> delete_channel_with_audit(channel, user)
      {:ok, %Channel{}}

  """
  def delete_channel_with_audit(%Channel{} = channel, %User{} = user) do
    # Log before delete since we need the channel ID
    changes = %{"deleted" => %{"from" => false, "to" => true}}

    case delete_channel(channel) do
      {:ok, deleted_channel} ->
        Audit.log_action(user, "deleted", deleted_channel, changes)
        {:ok, deleted_channel}

      error ->
        error
    end
  end

  alias InventorySync.Inventory.Product

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products do
    Repo.all(Product)
  end

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id), do: Repo.get!(Product, id)

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a product.

  ## Examples

      iex> update_product(product, %{field: new_value})
      {:ok, %Product{}}

      iex> update_product(product, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}

      iex> delete_product(product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end

  # ============================================================================
  # Audit-aware Product Operations
  # ============================================================================

  @doc """
  Creates a product and logs the action to the audit trail.

  ## Examples

      iex> create_product_with_audit(%{field: value}, user)
      {:ok, %Product{}}

  """
  def create_product_with_audit(attrs, %User{} = user) do
    case create_product(attrs) do
      {:ok, product} ->
        changes = Audit.calculate_changes(nil, Map.take(attrs, [:sku, :name, :total_quantity]))
        Audit.log_action(user, "created", product, changes)
        {:ok, product}

      error ->
        error
    end
  end

  @doc """
  Updates a product and logs the action to the audit trail.

  ## Examples

      iex> update_product_with_audit(product, %{field: new_value}, user)
      {:ok, %Product{}}

  """
  def update_product_with_audit(%Product{} = product, attrs, %User{} = user) do
    old_attrs = Map.take(product, [:sku, :name, :total_quantity])

    case update_product(product, attrs) do
      {:ok, updated_product} ->
        new_attrs = Map.take(updated_product, [:sku, :name, :total_quantity])
        changes = Audit.calculate_changes(old_attrs, new_attrs)

        unless changes == %{} do
          Audit.log_action(user, "updated", updated_product, changes)
        end

        {:ok, updated_product}

      error ->
        error
    end
  end

  @doc """
  Deletes a product and logs the action to the audit trail.

  ## Examples

      iex> delete_product_with_audit(product, user)
      {:ok, %Product{}}

  """
  def delete_product_with_audit(%Product{} = product, %User{} = user) do
    changes = %{"deleted" => %{"from" => false, "to" => true}}

    case delete_product(product) do
      {:ok, deleted_product} ->
        Audit.log_action(user, "deleted", deleted_product, changes)
        {:ok, deleted_product}

      error ->
        error
    end
  end

  alias InventorySync.Inventory.InventoryItem

  @doc """
  Returns the list of inventory_items.

  ## Examples

      iex> list_inventory_items()
      [%InventoryItem{}, ...]

  """
  def list_inventory_items do
    Repo.all(InventoryItem)
  end

  @doc """
  Returns the list of inventory_items for a specific product with channels preloaded.

  ## Examples

      iex> list_inventory_items_for_product(product_id)
      [%InventoryItem{}, ...]

  """
  def list_inventory_items_for_product(product_id) do
    InventoryItem
    |> where([i], i.product_id == ^product_id)
    |> preload(:channel)
    |> Repo.all()
  end

  @doc """
  Gets a single inventory_item.

  Raises `Ecto.NoResultsError` if the Inventory item does not exist.

  ## Examples

      iex> get_inventory_item!(123)
      %InventoryItem{}

      iex> get_inventory_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_inventory_item!(id), do: Repo.get!(InventoryItem, id)

  @doc """
  Creates a inventory_item.

  ## Examples

      iex> create_inventory_item(%{field: value})
      {:ok, %InventoryItem{}}

      iex> create_inventory_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_inventory_item(attrs) do
    %InventoryItem{}
    |> InventoryItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a inventory_item.

  ## Examples

      iex> update_inventory_item(inventory_item, %{field: new_value})
      {:ok, %InventoryItem{}}

      iex> update_inventory_item(inventory_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_inventory_item(%InventoryItem{} = inventory_item, attrs) do
    inventory_item
    |> InventoryItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a inventory_item.

  ## Examples

      iex> delete_inventory_item(inventory_item)
      {:ok, %InventoryItem{}}

      iex> delete_inventory_item(inventory_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_inventory_item(%InventoryItem{} = inventory_item) do
    Repo.delete(inventory_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking inventory_item changes.

  ## Examples

      iex> change_inventory_item(inventory_item)
      %Ecto.Changeset{data: %InventoryItem{}}

  """
  def change_inventory_item(%InventoryItem{} = inventory_item, attrs \\ %{}) do
    InventoryItem.changeset(inventory_item, attrs)
  end

  alias InventorySync.Inventory.SyncHistory

  def create_sync_history(attrs) do
    %SyncHistory{}
    |> SyncHistory.changeset(attrs)
    |> Repo.insert()
  end

  def list_recent_sync_history(limit \\ 10) do
    Repo.all(from s in SyncHistory, order_by: [desc: s.timestamp], limit: ^limit)
  end

  def count_syncs_today do
    today_start = DateTime.utc_now() |> DateTime.to_date() |> DateTime.new!(~T[00:00:00])
    Repo.one(from s in SyncHistory, where: s.timestamp >= ^today_start, select: count(s.id))
  end

  def count_errors_today do
    today_start = DateTime.utc_now() |> DateTime.to_date() |> DateTime.new!(~T[00:00:00])

    Repo.one(
      from s in SyncHistory,
        where: s.timestamp >= ^today_start and s.status == "error",
        select: count(s.id)
    )
  end

  @doc """
  Updates the quantity of a product and syncs it to all linked channels.
  """
  def update_product_quantity(product_id, new_quantity) do
    # 1. Update the Product
    product = get_product!(product_id)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:product, Product.changeset(product, %{total_quantity: new_quantity}))
    |> Ecto.Multi.run(:inventory_items, fn repo, _ ->
      # 2. Get all linked inventory items
      items =
        repo.all(from i in InventoryItem, where: i.product_id == ^product.id, preload: [:channel])

      # 3. Update their local quantities (optional, depending on business logic if we want to mirror quantity exactly)
      # For now let's assume we mirror the total quantity to all channels
      {_count, _updated_items} =
        repo.update_all(
          from(i in InventoryItem, where: i.product_id == ^product.id, select: i),
          set: [quantity: new_quantity, updated_at: DateTime.utc_now()]
        )

      # Since update_all doesn't return preloads, we might need to reload or just use the IDs from `items`
      # A better approach for the broadcast step is to iterate over `items`
      {:ok, items}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{product: product, inventory_items: items}} ->
        # Broadcast to each channel
        Enum.each(items, fn item ->
          # We send the updated quantity. Note: item.quantity in `items` is the OLD quantity before update_all
          # but we want to send `new_quantity`.
          Phoenix.PubSub.broadcast(
            InventorySync.PubSub,
            "channel:#{item.channel_id}",
            {:sync_inventory, %{item | quantity: new_quantity}}
          )
        end)

        {:ok, product}

      error ->
        error
    end
  end

  def get_chart_data do
    today_start = DateTime.utc_now() |> DateTime.to_date() |> DateTime.new!(~T[00:00:00])

    events = Repo.all(from s in SyncHistory, where: s.timestamp >= ^today_start)

    grouped = Enum.group_by(events, fn e -> e.timestamp.hour end)

    for h <- 0..23 do
      %{
        label: "#{h}:00",
        value: Map.get(grouped, h, []) |> length()
      }
    end
  end

  alias InventorySync.Inventory.Setting

  def get_setting(key, default \\ nil) do
    case Repo.get_by(Setting, key: key) do
      nil -> default
      setting -> setting.value
    end
  end

  def put_setting(key, value) do
    case Repo.get_by(Setting, key: key) do
      nil ->
        %Setting{}
        |> Setting.changeset(%{key: key, value: value})
        |> Repo.insert()

      setting ->
        setting
        |> Setting.changeset(%{value: value})
        |> Repo.update()
    end
  end

  alias InventorySync.Inventory.TeamMember

  def list_team_members do
    Repo.all(TeamMember)
  end

  def create_team_member(attrs) do
    %TeamMember{}
    |> TeamMember.changeset(attrs)
    |> Repo.insert()
  end

  def get_team_member!(id), do: Repo.get!(TeamMember, id)

  def update_team_member(%TeamMember{} = team_member, attrs) do
    team_member
    |> TeamMember.changeset(attrs)
    |> Repo.update()
  end

  def change_team_member(%TeamMember{} = team_member, attrs \\ %{}) do
    TeamMember.changeset(team_member, attrs)
  end

  # ============================================================================
  # Audit-aware TeamMember Operations
  # ============================================================================

  @doc """
  Creates a team member (invite) and logs the action to the audit trail.

  ## Examples

      iex> create_team_member_with_audit(%{field: value}, user)
      {:ok, %TeamMember{}}

  """
  def create_team_member_with_audit(attrs, %User{} = user) do
    case create_team_member(attrs) do
      {:ok, team_member} ->
        changes = Audit.calculate_changes(nil, Map.take(attrs, [:name, :email, :role]))
        Audit.log_action(user, "invited", team_member, changes)
        {:ok, team_member}

      error ->
        error
    end
  end

  @doc """
  Updates a team member and logs the action to the audit trail.

  ## Examples

      iex> update_team_member_with_audit(team_member, %{field: new_value}, user)
      {:ok, %TeamMember{}}

  """
  def update_team_member_with_audit(%TeamMember{} = team_member, attrs, %User{} = user) do
    old_attrs = Map.take(team_member, [:name, :email, :role])

    case update_team_member(team_member, attrs) do
      {:ok, updated_member} ->
        new_attrs = Map.take(updated_member, [:name, :email, :role])
        changes = Audit.calculate_changes(old_attrs, new_attrs)

        unless changes == %{} do
          Audit.log_action(user, "updated", updated_member, changes)
        end

        {:ok, updated_member}

      error ->
        error
    end
  end

  @doc """
  Deletes a team member and logs the action to the audit trail.

  ## Examples

      iex> delete_team_member_with_audit(team_member, user)
      {:ok, %TeamMember{}}

  """
  def delete_team_member(%TeamMember{} = team_member) do
    Repo.delete(team_member)
  end

  def delete_team_member_with_audit(%TeamMember{} = team_member, %User{} = user) do
    changes = %{"deleted" => %{"from" => false, "to" => true}}

    case delete_team_member(team_member) do
      {:ok, deleted_member} ->
        Audit.log_action(user, "deleted", deleted_member, changes)
        {:ok, deleted_member}

      error ->
        error
    end
  end

  # ============================================================================
  # Audit-aware Settings Operations
  # ============================================================================

  @doc """
  Updates a setting and logs the action to the audit trail.

  ## Examples

      iex> put_setting_with_audit("key", "value", user)
      {:ok, %Setting{}}

  """
  def put_setting_with_audit(key, value, %User{} = user) do
    old_value = get_setting(key)

    case put_setting(key, value) do
      {:ok, setting} ->
        changes = %{"value" => %{"from" => old_value, "to" => value}}
        # Use a special metadata for settings since they don't have a standard ID
        Audit.create_audit_log(%{
          action: "settings_changed",
          resource_type: "setting",
          resource_id: setting.id,
          changes: %{key => changes},
          user_id: user.id
        })

        {:ok, setting}

      error ->
        error
    end
  end
end
