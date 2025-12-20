defmodule InventorySync.InventoryAuditIntegrationTest do
  use InventorySync.DataCase

  alias InventorySync.Inventory
  alias InventorySync.Audit

  import InventorySync.AccountsFixtures
  import InventorySync.InventoryFixtures

  describe "channel audit integration" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "create_channel_with_audit/2 creates channel and logs audit", %{user: user} do
      attrs = %{
        name: "Shopify Store",
        platform: :shopify,
        credentials: Jason.encode!(%{api_key: "test"})
      }

      assert {:ok, channel} = Inventory.create_channel_with_audit(attrs, user)
      assert channel.name == "Shopify Store"

      # Verify audit log was created
      [audit_log] = Audit.list_audit_logs(resource_type: "channel", user_id: user.id)
      assert audit_log.action == "created"
      assert audit_log.resource_id == channel.id
      assert audit_log.changes["name"]["to"] == "Shopify Store"
    end

    test "update_channel_with_audit/3 updates channel and logs audit", %{user: user} do
      channel = channel_fixture()

      assert {:ok, updated_channel} =
               Inventory.update_channel_with_audit(channel, %{name: "Updated Store"}, user)

      assert updated_channel.name == "Updated Store"

      # Verify audit log was created
      logs = Audit.list_audit_logs(resource_type: "channel", action: "updated")
      assert length(logs) == 1

      [audit_log] = logs
      assert audit_log.resource_id == channel.id
      assert audit_log.changes["name"]["from"] == channel.name
      assert audit_log.changes["name"]["to"] == "Updated Store"
    end

    test "update_channel_with_audit/3 does not log when no changes", %{user: user} do
      channel = channel_fixture()

      # Update with same values
      assert {:ok, _updated_channel} =
               Inventory.update_channel_with_audit(channel, %{name: channel.name}, user)

      # Verify no audit log was created
      logs = Audit.list_audit_logs(resource_type: "channel", action: "updated")
      assert logs == []
    end

    test "delete_channel_with_audit/2 deletes channel and logs audit", %{user: user} do
      channel = channel_fixture()
      channel_id = channel.id

      assert {:ok, _deleted_channel} = Inventory.delete_channel_with_audit(channel, user)

      # Verify channel is deleted
      assert_raise Ecto.NoResultsError, fn ->
        Inventory.get_channel!(channel_id)
      end

      # Verify audit log was created
      [audit_log] = Audit.list_audit_logs(action: "deleted")
      assert audit_log.resource_type == "channel"
      assert audit_log.resource_id == channel_id
    end
  end

  describe "product audit integration" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "create_product_with_audit/2 creates product and logs audit", %{user: user} do
      attrs = %{
        sku: "TEST-SKU-001",
        name: "Test Product",
        total_quantity: 100
      }

      assert {:ok, product} = Inventory.create_product_with_audit(attrs, user)
      assert product.sku == "TEST-SKU-001"

      # Verify audit log was created
      [audit_log] = Audit.list_audit_logs(resource_type: "product", user_id: user.id)
      assert audit_log.action == "created"
      assert audit_log.resource_id == product.id
      assert audit_log.changes["sku"]["to"] == "TEST-SKU-001"
    end

    test "update_product_with_audit/3 updates product and logs audit", %{user: user} do
      product = product_fixture()

      assert {:ok, updated_product} =
               Inventory.update_product_with_audit(product, %{total_quantity: 200}, user)

      assert updated_product.total_quantity == 200

      # Verify audit log was created
      [audit_log] = Audit.list_audit_logs(resource_type: "product", action: "updated")
      assert audit_log.resource_id == product.id
      assert audit_log.changes["total_quantity"]["from"] == product.total_quantity
      assert audit_log.changes["total_quantity"]["to"] == 200
    end

    test "delete_product_with_audit/2 deletes product and logs audit", %{user: user} do
      product = product_fixture()
      product_id = product.id

      assert {:ok, _deleted_product} = Inventory.delete_product_with_audit(product, user)

      # Verify product is deleted
      assert_raise Ecto.NoResultsError, fn ->
        Inventory.get_product!(product_id)
      end

      # Verify audit log was created
      logs = Audit.list_audit_logs(resource_type: "product", action: "deleted")
      assert length(logs) == 1
      assert hd(logs).resource_id == product_id
    end
  end

  describe "team_member audit integration" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "create_team_member_with_audit/2 creates team member and logs audit", %{user: user} do
      attrs = %{
        name: "Jane Doe",
        email: "jane@example.com",
        role: "admin"
      }

      assert {:ok, team_member} = Inventory.create_team_member_with_audit(attrs, user)
      assert team_member.name == "Jane Doe"

      # Verify audit log was created with "invited" action
      [audit_log] = Audit.list_audit_logs(resource_type: "team_member", user_id: user.id)
      assert audit_log.action == "invited"
      assert audit_log.resource_id == team_member.id
      assert audit_log.changes["email"]["to"] == "jane@example.com"
    end

    test "update_team_member_with_audit/3 updates team member and logs audit", %{user: user} do
      team_member = team_member_fixture()

      assert {:ok, updated_member} =
               Inventory.update_team_member_with_audit(team_member, %{role: "owner"}, user)

      assert updated_member.role == "owner"

      # Verify audit log was created
      [audit_log] = Audit.list_audit_logs(resource_type: "team_member", action: "updated")
      assert audit_log.resource_id == team_member.id
      assert audit_log.changes["role"]["from"] == team_member.role
      assert audit_log.changes["role"]["to"] == "owner"
    end

    test "delete_team_member_with_audit/2 deletes team member and logs audit", %{user: user} do
      team_member = team_member_fixture()
      member_id = team_member.id

      assert {:ok, _deleted_member} = Inventory.delete_team_member_with_audit(team_member, user)

      # Verify team member is deleted
      assert_raise Ecto.NoResultsError, fn ->
        Inventory.get_team_member!(member_id)
      end

      # Verify audit log was created
      [audit_log] = Audit.list_audit_logs(resource_type: "team_member", action: "deleted")
      assert audit_log.resource_id == member_id
    end
  end

  describe "settings audit integration" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "put_setting_with_audit/3 creates setting and logs audit", %{user: user} do
      assert {:ok, setting} = Inventory.put_setting_with_audit("theme", "dark", user)
      assert setting.value == "dark"

      # Verify audit log was created
      [audit_log] = Audit.list_audit_logs(action: "settings_changed")
      assert audit_log.resource_type == "setting"
      assert audit_log.resource_id == setting.id
      assert audit_log.changes["theme"]["value"]["to"] == "dark"
    end

    test "put_setting_with_audit/3 updates setting and logs old value", %{user: user} do
      # First, set the value
      {:ok, _setting} = Inventory.put_setting("notification_email", "old@example.com")

      # Now update with audit
      assert {:ok, setting} =
               Inventory.put_setting_with_audit("notification_email", "new@example.com", user)

      assert setting.value == "new@example.com"

      # Verify audit log captures old and new values
      [audit_log] = Audit.list_audit_logs(action: "settings_changed")
      assert audit_log.changes["notification_email"]["value"]["from"] == "old@example.com"
      assert audit_log.changes["notification_email"]["value"]["to"] == "new@example.com"
    end
  end

  describe "audit log queries" do
    setup do
      user = user_fixture()
      {:ok, channel} = Inventory.create_channel_with_audit(channel_attrs(), user)
      {:ok, product} = Inventory.create_product_with_audit(product_attrs(), user)

      {:ok, user: user, channel: channel, product: product}
    end

    test "list_audit_logs_for_resource/2 returns logs for specific resource", %{
      user: user,
      channel: channel
    } do
      # Update the channel to create more logs
      {:ok, _} = Inventory.update_channel_with_audit(channel, %{name: "Updated"}, user)

      logs = Audit.list_audit_logs_for_resource("channel", channel.id)
      assert length(logs) == 2
      assert Enum.all?(logs, &(&1.resource_id == channel.id))
    end

    test "list_recent_audit_logs/1 returns logs with user preloaded", ctx do
      logs = Audit.list_recent_audit_logs(10)

      assert length(logs) >= 2

      Enum.each(logs, fn log ->
        assert Ecto.assoc_loaded?(log.user)
        assert log.user.id == ctx.user.id
      end)
    end

    test "count_audit_logs_today/0 returns accurate count", _ctx do
      count = Audit.count_audit_logs_today()
      # At least 2 logs from setup (channel + product creation)
      assert count >= 2
    end
  end

  # Helper functions to generate unique attributes
  defp channel_attrs do
    %{
      name: "Test Channel #{System.unique_integer([:positive])}",
      platform: :shopify,
      credentials: Jason.encode!(%{api_key: "test"})
    }
  end

  defp product_attrs do
    %{
      sku: "SKU-#{System.unique_integer([:positive])}",
      name: "Test Product",
      total_quantity: 100
    }
  end
end
