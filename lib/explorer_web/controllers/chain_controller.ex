defmodule ExplorerWeb.ChainController do
  use ExplorerWeb, :controller
  import Ecto.Query
  alias Explorer.Block
  alias Explorer.Transaction
  alias Explorer.Repo
  alias Explorer.BlockForm
  alias Explorer.BlockTransaction
  alias Explorer.TransactionForm

  def show(conn, _params) do
    blocks = Block
    |> order_by(desc: :number)
    |> limit(5)
    |> Repo.all
    |> Enum.map(&BlockForm.build/1)

    transaction_query = from transaction in Transaction,
      join: block_transaction in BlockTransaction,
        where: transaction.id == block_transaction.transaction_id,
      join: block in Block,
        where: block.id == block_transaction.block_id,
      limit: 5,
      order_by: block.number

    transactions = Repo.all(transaction_query) |> Enum.map(&TransactionForm.build/1)
    render(conn, "show.html", blocks: blocks, transactions: transactions)
  end
end
