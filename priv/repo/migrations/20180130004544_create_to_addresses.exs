defmodule Explorer.Repo.Migrations.CreateToAddresses do
  use Ecto.Migration

  def change do
    create table(:to_addresses, primary_key: false) do
      add :transaction_id, :bigint, null: false, primary_key: true
      add :address_id, :bigint, null: false, primary_key: true
      timestamps null: false
    end

    create index(:to_addresses, [:transaction_id, :address_id], unique: true)
    create index(:to_addresses, :transaction_id)
    create index(:to_addresses, :address_id)
  end
end
