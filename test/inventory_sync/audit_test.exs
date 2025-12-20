defmodule InventorySync.AuditTest do
  use InventorySync.DataCase

  alias InventorySync.Audit
  alias InventorySync.Audit.AuditLog

  import InventorySync.AccountsFixtures
  import InventorySync.InventoryFixtures

  describe "audit_logs" do
    @valid_attrs %{
      action: "created",
      resource_type: "channel",
      resource_id: 1,
      changes: %{"name" => %{"from" => nil, "to" => "Shopify Store"}}
    }

    @invalid_attrs %{action: nil, resource_type: nil, resource_id: nil}

    def audit_log_fixture(attrs \\ %{}) do
      user = attrs[:user] || user_fixture()

      {:ok, audit_log} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Map.put(:user_id, user.id)
        |> Audit.create_audit_log()

      audit_log
    end

    test "list_audit_logs/0 returns all audit_logs" do
      audit_log = audit_log_fixture()
      assert Audit.list_audit_logs() == [audit_log]
    end

    test "list_audit_logs/1 filters by resource_type" do
      user = user_fixture()
      channel_log = audit_log_fixture(user: user, resource_type: "channel")
      _product_log = audit_log_fixture(user: user, resource_type: "product", resource_id: 2)

      result = Audit.list_audit_logs(resource_type: "channel")
      assert length(result) == 1
      assert hd(result).id == channel_log.id
    end

    test "list_audit_logs/1 filters by user_id" do
      user1 = user_fixture()
      user2 = user_fixture()
      log1 = audit_log_fixture(user: user1)
      _log2 = audit_log_fixture(user: user2, resource_id: 2)

      result = Audit.list_audit_logs(user_id: user1.id)
      assert length(result) == 1
      assert hd(result).id == log1.id
    end

    test "list_audit_logs/1 filters by action" do
      user = user_fixture()
      created_log = audit_log_fixture(user: user, action: "created")
      _updated_log = audit_log_fixture(user: user, action: "updated", resource_id: 2)

      result = Audit.list_audit_logs(action: "created")
      assert length(result) == 1
      assert hd(result).id == created_log.id
    end

    test "list_audit_logs/1 limits results" do
      user = user_fixture()
      _log1 = audit_log_fixture(user: user, resource_id: 1)
      _log2 = audit_log_fixture(user: user, resource_id: 2)
      _log3 = audit_log_fixture(user: user, resource_id: 3)

      result = Audit.list_audit_logs(limit: 2)
      assert length(result) == 2
    end

    test "list_audit_logs_for_resource/2 returns logs for specific resource" do
      user = user_fixture()
      channel = channel_fixture()

      log1 = audit_log_fixture(user: user, resource_type: "channel", resource_id: channel.id)
      _log2 = audit_log_fixture(user: user, resource_type: "channel", resource_id: channel.id + 1)

      result = Audit.list_audit_logs_for_resource("channel", channel.id)
      assert length(result) == 1
      assert hd(result).id == log1.id
    end

    test "get_audit_log!/1 returns the audit_log with given id" do
      audit_log = audit_log_fixture()
      assert Audit.get_audit_log!(audit_log.id) == audit_log
    end

    test "create_audit_log/1 with valid data creates an audit_log" do
      user = user_fixture()

      valid_attrs = %{
        action: "created",
        resource_type: "channel",
        resource_id: 123,
        user_id: user.id,
        changes: %{"name" => %{"from" => nil, "to" => "My Channel"}},
        metadata: %{"ip_address" => "127.0.0.1"}
      }

      assert {:ok, %AuditLog{} = audit_log} = Audit.create_audit_log(valid_attrs)
      assert audit_log.action == "created"
      assert audit_log.resource_type == "channel"
      assert audit_log.resource_id == 123
      assert audit_log.user_id == user.id
      assert audit_log.changes == %{"name" => %{"from" => nil, "to" => "My Channel"}}
      assert audit_log.metadata == %{"ip_address" => "127.0.0.1"}
    end

    test "create_audit_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Audit.create_audit_log(@invalid_attrs)
    end

    test "create_audit_log/1 requires user_id" do
      attrs = Map.put(@valid_attrs, :user_id, nil)
      assert {:error, %Ecto.Changeset{}} = Audit.create_audit_log(attrs)
    end

    test "log_action/4 creates an audit log for a resource" do
      user = user_fixture()
      channel = channel_fixture()

      changes = %{"name" => %{"from" => "Old Name", "to" => "New Name"}}

      assert {:ok, %AuditLog{} = log} =
               Audit.log_action(user, "updated", channel, changes)

      assert log.action == "updated"
      assert log.resource_type == "channel"
      assert log.resource_id == channel.id
      assert log.user_id == user.id
      assert log.changes == changes
    end

    test "log_action/4 handles different resource types" do
      user = user_fixture()
      product = product_fixture()

      assert {:ok, %AuditLog{} = log} =
               Audit.log_action(user, "deleted", product, %{})

      assert log.resource_type == "product"
      assert log.resource_id == product.id
    end

    test "count_audit_logs_today/0 returns count of today's logs" do
      user = user_fixture()
      _log1 = audit_log_fixture(user: user, resource_id: 1)
      _log2 = audit_log_fixture(user: user, resource_id: 2)

      assert Audit.count_audit_logs_today() == 2
    end

    test "list_recent_audit_logs/1 returns recent logs with user preloaded" do
      user = user_fixture()
      _log = audit_log_fixture(user: user)

      [result] = Audit.list_recent_audit_logs(10)
      assert Ecto.assoc_loaded?(result.user)
      assert result.user.id == user.id
    end
  end
end
