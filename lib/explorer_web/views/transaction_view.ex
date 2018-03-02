defmodule ExplorerWeb.TransactionView do
  use ExplorerWeb, :view

  alias Cldr.Number
  alias Explorer.Receipt

  @dialyzer :no_match

  def format_gas_limit(gas) do
    gas
    |> Number.to_string!()
  end

  def status(transaction) do
    receipt = transaction.receipt || Receipt.null()

    %{
      0 => %{true => :out_of_gas, false => :failed},
      1 => %{true => :success, false => :success}
    }
    |> Map.get(receipt.status, %{true: :pending, false: :pending})
    |> Map.get(receipt.gas_used == transaction.gas)
  end
end
