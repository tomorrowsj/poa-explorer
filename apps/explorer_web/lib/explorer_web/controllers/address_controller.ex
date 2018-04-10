defmodule ExplorerWeb.AddressController do
  use ExplorerWeb, :controller

  alias Explorer.Address.Service, as: Address
  alias Explorer.Repo.NewRelic, as: Repo
  alias Explorer.Transaction
  alias Explorer.Transaction.Service.Query
  alias Explorer.TransactionForm

  def show(conn, %{"id" => id, "locale" => locale}) do
    redirect(conn, to: address_transaction_path(conn, :index, locale, id))
  end
end
