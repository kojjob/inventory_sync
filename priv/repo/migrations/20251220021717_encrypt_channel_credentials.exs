defmodule InventorySync.Repo.Migrations.EncryptChannelCredentials do
  use Ecto.Migration

  def up do
    # Add temporary encrypted column
    alter table(:channels) do
      add :credentials_encrypted, :binary
    end

    # NOTE: We don't migrate existing credentials because they're not encrypted.
    # Existing channels will need to have their credentials re-entered.
    # This is acceptable for a development blocker fix.

    # Drop old column and rename new one
    alter table(:channels) do
      remove :credentials
    end

    rename table(:channels), :credentials_encrypted, to: :credentials
  end

  def down do
    # Reverse the migration
    rename table(:channels), :credentials, to: :credentials_encrypted

    alter table(:channels) do
      add :credentials, :jsonb
    end

    # NOTE: We don't try to decrypt and restore credentials.
    # Rolling back this migration will result in empty credentials.

    alter table(:channels) do
      remove :credentials_encrypted
    end
  end
end
