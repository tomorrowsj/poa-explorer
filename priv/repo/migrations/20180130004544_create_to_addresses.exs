defmodule Explorer.Repo.Migrations.CreateToAddresses do
  use Ecto.Migration

  def change do
    create table(:to_addresses, primary_key: false) do
      add :transaction_id, references(:transactions, on_delete: :delete_all),
        null: false, primary_key: true
      add :address_id, references(:addresses, on_delete: :delete_all),
        null: false
      timestamps null: false
    end

    create index(:to_addresses, :transaction_id, unique: true)
    create index(:to_addresses, :address_id)
  end
end
