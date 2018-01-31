defmodule Explorer.ToAddress do
  use Ecto.Schema
  import Ecto.Changeset
  alias Explorer.ToAddress

  @primary_key false
  schema "to_addresses" do
    belongs_to :transaction, Explorer.Transaction, primary_key: true
    belongs_to :address, Explorer.Address, primary_key: true
  end

  def changeset(%ToAddress{} = to_address, attrs \\ %{}) do
    to_address
    |> cast(attrs, [:transaction_id, :address_id])
  end
end
