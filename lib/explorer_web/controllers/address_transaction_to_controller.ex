defmodule ExplorerWeb.AddressTransactionToController do
  @moduledoc """
    Display all the Transactions that terminate at this Address.
  """

  use ExplorerWeb, :controller

  alias Explorer.Address.Service, as: Address
  alias Explorer.Repo.NewRelic, as: Repo
  alias Explorer.Transaction
  alias Explorer.Transaction.Service.Query

  def index(conn, %{"address_id" => address_hash}) do
    address = Address.by_hash(address_hash)

    query =
      Transaction
      |> Query.to_address(address.id)
      |> Query.include_addresses()
      |> Query.include_receipt()
      |> Query.require_block()
      |> Query.chron()

    render(conn, "index.html", transactions: query |> Repo.all(), address_hash: address_hash)
  end
end
