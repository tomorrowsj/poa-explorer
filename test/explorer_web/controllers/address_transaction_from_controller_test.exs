defmodule ExplorerWeb.AddressTransactionFromControllerTest do
  use ExplorerWeb.ConnCase

  import ExplorerWeb.Router.Helpers, only: [address_transaction_from_path: 4]

  describe "GET index/2" do
    test "returns transactions from this address", %{conn: conn} do
      address = insert(:address)
      transaction = insert(:transaction, hash: "0xsnacks", from_address_id: address.id)
      insert(:receipt, transaction: transaction)
      block = insert(:block)
      insert(:block_transaction, transaction: transaction, block: block)

      conn =
        get(conn, address_transaction_from_path(ExplorerWeb.Endpoint, :index, :en, address.hash))

      assert length(conn.assigns.transactions) == 1
      assert List.first(conn.assigns.transactions).hash == "0xsnacks"
    end

    test "returns transactions from this address that do not have a receipt", %{conn: conn} do
      address = insert(:address)
      transaction = insert(:transaction, from_address_id: address.id)
      block = insert(:block)
      insert(:block_transaction, transaction: transaction, block: block)

      conn =
        get(conn, address_transaction_from_path(ExplorerWeb.Endpoint, :index, :en, address.hash))

      assert length(conn.assigns.transactions) == 1
    end

    test "returns transactions from this address that do not have a block", %{conn: conn} do
      address = insert(:address)
      insert(:transaction, from_address_id: address.id)

      conn =
        get(conn, address_transaction_from_path(ExplorerWeb.Endpoint, :index, :en, address.hash))

      assert length(conn.assigns.transactions) == 1
    end

    test "does not return transactions to this address", %{conn: conn} do
      address = insert(:address)
      other_address = insert(:address)
      transaction = insert(:transaction, hash: "0xsnacks", from_address_id: other_address.id)
      insert(:receipt, transaction: transaction)
      block = insert(:block)
      insert(:block_transaction, transaction: transaction, block: block)

      conn =
        get(conn, address_transaction_from_path(ExplorerWeb.Endpoint, :index, :en, address.hash))

      assert length(conn.assigns.transactions) == 0
    end

    test "paginates transactions for this address", %{conn: conn} do
      insert_list(11, :transaction)

      assert length(conn.assigns.transactions) == 10
    end
  end
end
