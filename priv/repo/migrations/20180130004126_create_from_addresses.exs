defmodule Explorer.Repo.Migrations.CreateFromAddresses do
  use Ecto.Migration

  def change do
    create table(:from_addresses, primary_key: false) do
      add :transaction_id, :bigint, null: false, primary_key: true
      add :address_id, :bigint, null: false, primary_key: true
    end

    create index(:from_addresses, [:transaction_id, :address_id], unique: true)
    create index(:from_addresses, :transaction_id)
    create index(:from_addresses, :address_id)
  end
end
