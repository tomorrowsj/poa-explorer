defmodule ExplorerWeb.AddressTransactionViewTest do
  use Explorer.DataCase

  alias ExplorerWeb.AddressTransactionView

  test "calculate_fee formats the fee for a successful transaction" do
    insert(:block, number: 24)
    time = Timex.now() |> Timex.shift(hours: -2)

    block =
      insert(:block, %{
        number: 1,
        gas_used: 99523,
        timestamp: time
      })

    to_address = insert(:address, hash: "0xsleepypuppy")
    from_address = insert(:address, hash: "0xilovefrogs")

    transaction =
      insert(
        :transaction,
        inserted_at: Timex.parse!("1970-01-01T00:00:18-00:00", "{ISO:Extended}"),
        updated_at: Timex.parse!("1980-01-01T00:00:18-00:00", "{ISO:Extended}"),
        to_address_id: to_address.id,
        from_address_id: from_address.id,
        gas_price: Decimal.new(1_000_000_000.0)
      )
      |> with_block(block)

    insert(:receipt, status: 1, gas_used: Decimal.new(435_334.0), transaction: transaction)

    transaction =
      transaction
      |> Repo.preload([:receipt])

    assert AddressTransactionView.calculate_fee(transaction) == "0.000435334"
  end

  test "calculate_fee returns max_gas for pending transaction" do
    to_address = insert(:address, hash: "0xchadmuska")
    from_address = insert(:address, hash: "0xtonyhawk")

    transaction =
      insert(
        :transaction,
        inserted_at: Timex.parse!("1970-01-01T00:00:18-00:00", "{ISO:Extended}"),
        updated_at: Timex.parse!("1980-01-01T00:00:18-00:00", "{ISO:Extended}"),
        to_address_id: to_address.id,
        from_address_id: from_address.id,
        gas: Decimal.new(21000.0),
        gas_price: Decimal.new(1_000_000_000.0)
      )
      |> Repo.preload([:to_address, :from_address, :receipt])

    assert AddressTransactionView.calculate_fee(transaction) == "<= 0.000021"
  end
end
