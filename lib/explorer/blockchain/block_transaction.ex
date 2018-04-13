defmodule Explorer.Blockchain.BlockTransaction do
  @moduledoc """
  TODO
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Explorer.Blockchain.{BlockTransaction, Block, Transaction}

  @primary_key false
  schema "block_transactions" do
    belongs_to :block, Block
    belongs_to :transaction, Transaction, primary_key: true
    timestamps()
  end

  @required_attrs ~w(block_id transaction_id)a

  def changeset(%BlockTransaction{} = block_transaction, attrs \\ %{}) do
    block_transaction
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
    |> cast_assoc(:block)
    |> cast_assoc(:transaction)
    |> unique_constraint(:transaction_id, name: :block_transactions_transaction_id_index)
  end
end