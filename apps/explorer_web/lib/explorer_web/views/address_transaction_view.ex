defmodule ExplorerWeb.AddressTransactionView do
  use ExplorerWeb, :view

  alias ExplorerWeb.WeiConverter

  @spec format_balance(nil) :: String.t()
  def format_balance(nil), do: "0"

  @spec format_balance(Decimal.t()) :: String.t()
  def format_balance(balance) do
    balance
    |> WeiConverter.to_ether()
    |> Decimal.to_string(:normal)
  end
end
