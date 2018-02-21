defmodule Explorer.InternalTransactionTest do
  use Explorer.DataCase

  alias Explorer.InternalTransaction

  describe "changeset/2" do
    test "with valid attributes" do
      transaction = insert(:transaction)
      changeset = InternalTransaction.changeset(%InternalTransaction{}, %{transaction: transaction, index: 0, call_type: "call", trace_address: [0, 1], value: 100, gas: 100, gas_used: 100, input: "pintos", output: "refried"})
      assert changeset.valid?
    end

    test "with invalid attributes" do
      changeset = InternalTransaction.changeset(%InternalTransaction{}, %{falala: "falafel"})
      refute changeset.valid?
    end
  end
end
