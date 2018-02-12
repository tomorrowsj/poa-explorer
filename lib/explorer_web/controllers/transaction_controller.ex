defmodule ExplorerWeb.TransactionController do
  use ExplorerWeb, :controller

  import Ecto.Query

  alias Explorer.Repo.NewRelic, as: Repo
  alias Explorer.Transaction
  alias Explorer.TransactionForm

  def index(conn, params) do
    query = from transaction in Transaction,
      join: block in assoc(transaction, :block),
      join: to_address in assoc(transaction, :to_address),
      join: from_address in assoc(transaction, :from_address),
      preload: [block: block, to_address: to_address, from_address: from_address],
      order_by: [desc: block.timestamp]

    transactions = Repo.paginate(query, params)

    render(conn, "index.html", transactions: transactions)
  end

  def show(conn, params) do
    hash = String.downcase(params["id"])
    query = from transaction in Transaction,
      join: block in assoc(transaction, :block),
      join: to_address in assoc(transaction, :to_address),
      join: from_address in assoc(transaction, :from_address),
      preload: [block: block, to_address: to_address, from_address: from_address],
      where: fragment("lower(?)", transaction.hash) == ^hash,
      limit: 1

    transaction = query |> Repo.one |> TransactionForm.build

    render(conn, "show.html", transaction: transaction)
  end
end
