defmodule Explorer.TransactionFormTest do
  use Explorer.DataCase
  alias Explorer.TransactionForm

  setup _context do
    date = "Feb-02-2010 10:48:56 AM Etc/UTC"
    block = insert(:block, %{
      number: 622,
      gas_used: 99523,
      timestamp: Timex.parse!(date, "%b-%d-%Y %H:%M:%S %p %Z", :strftime),
    })
    transaction = insert(:transaction, block: block)
    to_address = insert(:address, hash: "0xsleepypuppy")
    from_address = insert(:address, hash: "0xilovefrogs")
    insert(:to_address, transaction: transaction, address: to_address)
    insert(:from_address, transaction: transaction, address: from_address)
    form = TransactionForm.build(transaction)
    {:ok, %{form: form}}
  end

  describe "build/1" do
    test "that it has a block number", %{form: form} do
      assert form.block_number == 622
    end

    test "that it returns the block's age" do
      block = insert(:block, %{
        number: 622,
        gas_used: 99523,
        timestamp: Timex.now |> Timex.shift(hours: -2),
      })
      transaction = insert(:transaction, block: block)
      to_address = insert(:address, hash: "0xsiskelnebert")
      from_address = insert(:address, hash: "0xleonardmaltin")
      insert(:to_address, transaction: transaction, address: to_address)
      insert(:from_address, transaction: transaction, address: from_address)
      assert TransactionForm.build(transaction).age == "2 hours ago"
    end

    test "formats the block's timestamp", %{form: form} do
      assert form.formatted_timestamp == "Feb-02-2010 10:48:56 AM Etc/UTC"
    end

    test "that it returns the cumulative gas used for validating the block", %{form: form} do
      assert form.cumulative_gas_used == 99523
    end

    test "that it returns a 'to address'", %{form: form} do
      assert form.to_address == "0xsleepypuppy"
    end

    test "that it returns a 'from address'", %{form: form} do
      assert form.from_address == "0xilovefrogs"
    end
  end
end
