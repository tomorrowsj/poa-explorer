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

  def calculate_fee(transaction) do
    case transaction.receipt do
      nil ->
        "<= " <> something(transaction.gas, transaction.gas_price)

      receipt ->
        something(receipt.gas_used, transaction.gas_price)
    end
  end

  defp something(gas, gas_price) do
    gas
    |> Decimal.mult(gas_price)
    |> WeiConverter.to_ether()
    |> Decimal.to_string(:normal)
  end
end
