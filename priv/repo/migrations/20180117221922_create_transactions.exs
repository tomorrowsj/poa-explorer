defmodule Explorer.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :hash, :string, null: false
      add :block_id, references(:blocks, on_delete: :delete_all), null: false
      timestamps null: false
    end

    create unique_index(:transactions, [:hash])
    create index(:transactions, [:block_id])
  end
end
