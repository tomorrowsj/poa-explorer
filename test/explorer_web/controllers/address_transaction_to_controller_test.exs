defmodule ExplorerWeb.AddressTransactionToControllerTest do
  use ExplorerWeb.ConnCase

  import ExplorerWeb.Router.Helpers, only: [address_transaction_to_path: 4]

  describe "GET index/2" do
    test "returns transactions to this address", %{conn: conn} do
      address = insert(:address)
      transaction = insert(:transaction, hash: "0xsnacks", to_address_id: address.id)
      insert_list(12, :transaction, to_address_id: address.id)
      insert(:receipt, transaction: transaction)
      block = insert(:block)
      insert(:block_transaction, transaction: transaction, block: block)

      conn =
        get(conn, address_transaction_to_path(ExplorerWeb.Endpoint, :index, :en, address.hash))

      assert length(conn.assigns.transactions) == 10
      assert List.first(conn.assigns.transactions).hash == "0xsnacks"
    end

    test "returns transactions to this address without a receipt", %{conn: conn} do
      address = insert(:address)
      transaction = insert(:transaction, to_address_id: address.id)
      block = insert(:block)
      insert(:block_transaction, transaction: transaction, block: block)

      conn =
        get(conn, address_transaction_to_path(ExplorerWeb.Endpoint, :index, :en, address.hash))

      assert length(conn.assigns.transactions) == 1
    end

    test "does not return transactions from this address", %{conn: conn} do
      address = insert(:address)
      other_address = insert(:address)
      transaction = insert(:transaction, hash: "0xsnacks", to_address_id: other_address.id)
      block = insert(:block)
      insert(:block_transaction, transaction: transaction, block: block)

      conn =
        get(conn, address_transaction_to_path(ExplorerWeb.Endpoint, :index, :en, address.hash))

      assert length(conn.assigns.transactions) == 0
    end

    test "returns a page with ten transactions", %{conn: conn} do
  end
end
