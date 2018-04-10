defmodule ExplorerWeb.AddressController do
  use ExplorerWeb, :controller

  alias Explorer.Address.Service, as: Address
  alias Explorer.Repo.NewRelic, as: Repo
  alias Explorer.Transaction
  alias Explorer.Transaction.Service.Query
  alias Explorer.TransactionForm

  def show(conn, %{"id" => id} = params) do
    address = id |> Address.by_hash()

    query =
      Transaction
      |> Query.by_address(address.id)
      |> Query.include_addresses()
      |> Query.require_receipt()
      |> Query.require_block()
      |> Query.chron()

    page = Repo.paginate(query, params)
    entries = Enum.map(page.entries, &TransactionForm.build_and_merge/1)

    render(
      conn,
      "show.html",
      address: address,
      transactions: Map.put(page, :entries, entries)
    )
  end
end
