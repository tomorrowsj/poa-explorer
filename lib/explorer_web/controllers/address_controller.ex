defmodule ExplorerWeb.AddressController do
  use ExplorerWeb, :controller

  alias Explorer.Address.Service, as: Address

  def show(conn, %{"id" => id}) do
    address = id |> Address.by_hash()
    parity_host = Application.get_env(:ethereumex, :url)
    render(conn, "show.html", address: address, parity_host: parity_host)
  end
end
