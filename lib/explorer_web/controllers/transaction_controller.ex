defmodule ExplorerWeb.TransactionController do
  use ExplorerWeb, :controller
  import Ecto.Query
  alias Explorer.Block
  alias Explorer.BlockTransaction
  alias Explorer.Transaction
  alias Explorer.Repo
  alias Explorer.TransactionForm

  def index(conn, params) do
    query = from transaction in Transaction,
      left_join: block_transaction in assoc(transaction, :block_transaction),
      left_join: block in assoc(block_transaction, :block),
      preload: [block_transaction: block_transaction, block: block],

      # preload: [block: block],
      order_by: [asc: block.inserted_at]

    first_transaction = Repo.all(query) |> List.first
    IO.inspect(first_transaction)

    transactions = Repo.paginate(query, params)

    render(conn, "index.html", transactions: transactions)
  end

  def show(conn, params) do
    transaction = Transaction
      |> where(hash: ^params["id"])
      |> first
      |> Repo.one
      |> TransactionForm.build

    render(conn, "show.html", transaction: transaction)
  end
end
