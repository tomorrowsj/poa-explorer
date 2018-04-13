defmodule Explorer.Repo.Migrations.CreateBlockTransactions do
  use Ecto.Migration

  def change do
    create table(:block_transactions, primary_key: false) do
      add :block_id, references(:blocks, on_delete: :delete_all)
      add :transaction_id, references(:transactions, on_delete: :delete_all),
        primary_key: true
      timestamps null: false
    end

    create unique_index(:block_transactions, :transaction_id)
    create unique_index(:block_transactions, [:block_id, :transaction_id])
  end
end
