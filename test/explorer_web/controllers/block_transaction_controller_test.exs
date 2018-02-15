defmodule ExplorerWeb.BlockTransactionControllerTest do
  use ExplorerWeb.ConnCase

  describe "GET index/2" do
    test "returns a list of transactions for a block", %{conn: conn} do
      block = insert(:block, number: 88)
      first_transaction = insert(:transaction, hash: "0xsnacks") |> with_block(block)
      second_transaction = insert(:transaction) |> with_block(block)
      insert(:transaction)
      insert(:transaction_receipt, transaction: first_transaction, index: 1)
      insert(:transaction_receipt, transaction: second_transaction, index: 2)
      conn = get(conn, "/en/blocks/88/transactions")

      assert List.first(conn.assigns.transactions).hash == "0xsnacks"
      assert length(conn.assigns.transactions) == 2
    end
  end
end
