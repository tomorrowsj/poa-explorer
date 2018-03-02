defmodule ExplorerWeb.TransactionViewTest do
  use ExplorerWeb.ConnCase, async: true

  alias ExplorerWeb.TransactionView
  alias Explorer.Repo

  describe "status/1" do
    test "is pending when there is no receipt" do
      transaction = Repo.preload(insert(:transaction), :receipt)
      assert(TransactionView.status(transaction) == :pending)
    end

    test "is successful when there is a success receipt" do
      transaction = insert(:transaction)
      insert(:receipt, status: 1, transaction: transaction)
      transaction = Repo.preload(transaction, :receipt)
      assert(TransactionView.status(transaction) == :success)
    end
  end
end
