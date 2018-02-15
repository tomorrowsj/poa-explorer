defmodule ExplorerWeb.BlockTransactionController do
  use ExplorerWeb, :controller

  import Ecto.Query

  alias Explorer.Repo.NewRelic, as: Repo
  alias Explorer.Transaction
  alias Explorer.TransactionForm

  def index(conn, params) do
    block_number = params["block_id"]
    query = from transaction in Transaction,
      inner_join: block in assoc(transaction, :block),
      left_join: receipt in assoc(transaction, :receipt),
      preload: [:block, :receipt, :to_address, :from_address],
      order_by: [asc: receipt.index],
      where: block.number == ^block_number
    transactions =
      query
      |> Repo.all()
      |> Enum.map(&TransactionForm.build_and_merge/1)
    render(conn, "index.html", transactions: transactions, block_number: block_number)
  end
end
