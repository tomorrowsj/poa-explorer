defmodule Explorer.Repo.Migrations.MoveAddressKeysToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :to_address_id, references(:addresses, on_delete: :delete_all)
      add :from_address_id, references(:addresses, on_delete: :delete_all)
    end
  end


end
