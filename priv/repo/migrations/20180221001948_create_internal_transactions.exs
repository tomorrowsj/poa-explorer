defmodule Explorer.Repo.Migrations.CreateInternalTransactions do
  use Ecto.Migration

  def change do
    create table(:internal_transactions) do
      add :transaction_id, references(:transactions), null: false
      add :index, :integer, null: false
      add :call_type, :string, null: false
      add :trace_address, {:array, :integer}, null: false
      add :value, :numeric, precision: 100, null: false
      add :gas, :numeric, precision: 100, null: false
      add :gas_used, :numeric, precision: 100, null: false
      add :input, :string, null: false
      add :output, :string, null: false
      timestamps null: false
    end

    create index(:internal_transactions, :transaction_id)
  end
end
