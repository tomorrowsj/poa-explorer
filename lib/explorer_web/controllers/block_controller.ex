defmodule ExplorerWeb.BlockController do
  use ExplorerWeb, :controller
  import Ecto.Query
  alias Explorer.Block
  alias Explorer.Repo
  alias Explorer.BlockForm

  def index(conn, params) do
    query = from block in Block,
      left_join: block_transaction in assoc(block, :block_transactions),
      left_join: transactions in assoc(block_transaction, :transaction),
      preload: [transactions: transactions]

    blocks = query |> Block.latest |> Repo.paginate(params)

    render(conn, "index.html", blocks: blocks)
  end

  def show(conn, params) do
    block = Block
      |> where(number: ^params["id"])
      |> first |> Repo.one
      |> BlockForm.build
    render(conn, "show.html", block: block)
  end
end
