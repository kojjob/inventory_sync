defmodule InventorySync.InventoryTest do
  use InventorySync.DataCase

  alias InventorySync.Inventory

  describe "channels" do
    alias InventorySync.Inventory.Channel

    import InventorySync.InventoryFixtures

    @invalid_attrs %{active: nil, name: nil, credentials: nil, platform: nil}

    test "list_channels/0 returns all channels" do
      channel = channel_fixture()
      assert Inventory.list_channels() == [channel]
    end

    test "get_channel!/1 returns the channel with given id" do
      channel = channel_fixture()
      assert Inventory.get_channel!(channel.id) == channel
    end

    test "create_channel/1 with valid data creates a channel" do
      valid_attrs = %{active: true, name: "some name", credentials: Jason.encode!(%{}), platform: :shopify}

      assert {:ok, %Channel{} = channel} = Inventory.create_channel(valid_attrs)
      assert channel.active == true
      assert channel.name == "some name"
      assert channel.credentials == Jason.encode!(%{})
      assert channel.platform == :shopify
    end

    test "create_channel/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_channel(@invalid_attrs)
    end

    test "update_channel/2 with valid data updates the channel" do
      channel = channel_fixture()
      update_attrs = %{active: false, name: "some updated name", credentials: Jason.encode!(%{}), platform: :amazon}

      assert {:ok, %Channel{} = channel} = Inventory.update_channel(channel, update_attrs)
      assert channel.active == false
      assert channel.name == "some updated name"
      assert channel.credentials == Jason.encode!(%{})
      assert channel.platform == :amazon
    end

    test "update_channel/2 with invalid data returns error changeset" do
      channel = channel_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_channel(channel, @invalid_attrs)
      assert channel == Inventory.get_channel!(channel.id)
    end

    test "delete_channel/1 deletes the channel" do
      channel = channel_fixture()
      assert {:ok, %Channel{}} = Inventory.delete_channel(channel)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_channel!(channel.id) end
    end

    test "change_channel/1 returns a channel changeset" do
      channel = channel_fixture()
      assert %Ecto.Changeset{} = Inventory.change_channel(channel)
    end
  end

  describe "products" do
    alias InventorySync.Inventory.Product

    import InventorySync.InventoryFixtures

    @invalid_attrs %{name: nil, sku: nil, total_quantity: nil}

    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Inventory.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Inventory.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{name: "some name", sku: "some sku", total_quantity: 42}

      assert {:ok, %Product{} = product} = Inventory.create_product(valid_attrs)
      assert product.name == "some name"
      assert product.sku == "some sku"
      assert product.total_quantity == 42
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      update_attrs = %{name: "some updated name", sku: "some updated sku", total_quantity: 43}

      assert {:ok, %Product{} = product} = Inventory.update_product(product, update_attrs)
      assert product.name == "some updated name"
      assert product.sku == "some updated sku"
      assert product.total_quantity == 43
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_product(product, @invalid_attrs)
      assert product == Inventory.get_product!(product.id)
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Inventory.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Inventory.change_product(product)
    end
  end

  describe "inventory_items" do
    alias InventorySync.Inventory.InventoryItem

    import InventorySync.InventoryFixtures

    @invalid_attrs %{external_id: nil, platform_sku: nil, quantity: nil}

    test "list_inventory_items/0 returns all inventory_items" do
      inventory_item = inventory_item_fixture()
      assert Inventory.list_inventory_items() == [inventory_item]
    end

    test "list_inventory_items_for_product/1 returns inventory items for a specific product with channels preloaded" do
      product1 = product_fixture(sku: "PROD-001")
      product2 = product_fixture(sku: "PROD-002")
      channel1 = channel_fixture(name: "Shopify Store")
      channel2 = channel_fixture(name: "Amazon Store")

      # Create inventory items for product1
      item1 = inventory_item_fixture(product_id: product1.id, channel_id: channel1.id, platform_sku: "SHOP-001")
      item2 = inventory_item_fixture(product_id: product1.id, channel_id: channel2.id, platform_sku: "AMZN-001")

      # Create inventory item for product2 (should not be returned)
      _item3 = inventory_item_fixture(product_id: product2.id, channel_id: channel1.id, platform_sku: "SHOP-002")

      items = Inventory.list_inventory_items_for_product(product1.id)

      assert length(items) == 2
      assert Enum.any?(items, fn item -> item.id == item1.id end)
      assert Enum.any?(items, fn item -> item.id == item2.id end)

      # Verify channels are preloaded
      first_item = List.first(items)
      assert Ecto.assoc_loaded?(first_item.channel)
      assert first_item.channel.name in ["Shopify Store", "Amazon Store"]
    end

    test "get_inventory_item!/1 returns the inventory_item with given id" do
      inventory_item = inventory_item_fixture()
      assert Inventory.get_inventory_item!(inventory_item.id) == inventory_item
    end

    test "create_inventory_item/1 with valid data creates a inventory_item" do
      channel = channel_fixture()
      product = product_fixture()
      valid_attrs = %{external_id: "some external_id", platform_sku: "some platform_sku", quantity: 42, channel_id: channel.id, product_id: product.id}

      assert {:ok, %InventoryItem{} = inventory_item} = Inventory.create_inventory_item(valid_attrs)
      assert inventory_item.external_id == "some external_id"
      assert inventory_item.platform_sku == "some platform_sku"
      assert inventory_item.quantity == 42
    end

    test "create_inventory_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_inventory_item(@invalid_attrs)
    end

    test "update_inventory_item/2 with valid data updates the inventory_item" do
      inventory_item = inventory_item_fixture()
      update_attrs = %{external_id: "some updated external_id", platform_sku: "some updated platform_sku", quantity: 43}

      assert {:ok, %InventoryItem{} = inventory_item} = Inventory.update_inventory_item(inventory_item, update_attrs)
      assert inventory_item.external_id == "some updated external_id"
      assert inventory_item.platform_sku == "some updated platform_sku"
      assert inventory_item.quantity == 43
    end

    test "update_inventory_item/2 with invalid data returns error changeset" do
      inventory_item = inventory_item_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_inventory_item(inventory_item, @invalid_attrs)
      assert inventory_item == Inventory.get_inventory_item!(inventory_item.id)
    end

    test "delete_inventory_item/1 deletes the inventory_item" do
      inventory_item = inventory_item_fixture()
      assert {:ok, %InventoryItem{}} = Inventory.delete_inventory_item(inventory_item)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_inventory_item!(inventory_item.id) end
    end

    test "change_inventory_item/1 returns a inventory_item changeset" do
      inventory_item = inventory_item_fixture()
      assert %Ecto.Changeset{} = Inventory.change_inventory_item(inventory_item)
    end
  end
end
