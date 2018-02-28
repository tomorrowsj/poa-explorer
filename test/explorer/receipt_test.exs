defmodule Explorer.ReceiptTest do
  use Explorer.DataCase

  alias Explorer.Receipt

  describe "changeset/2" do
    test "accepts valid attributes" do
      params = params_for(:receipt)
      changeset = Receipt.changeset(%Receipt{}, params)
      assert changeset.valid?
    end

    test "rejects missing attributes" do
      params = params_for(:receipt, cumulative_gas_used: nil)
      changeset = Receipt.changeset(%Receipt{}, params)
      refute changeset.valid?
    end

    test "accepts logs" do
      address = insert(:address)
      log_params = params_for(:log, address: address)
      params = params_for(:receipt, logs: [log_params])
      changeset = Receipt.changeset(%Receipt{}, params)
      assert changeset.valid?
    end

    test "saves logs for the receipt" do
      address = insert(:address)
      log_params = params_for(:log, address: address)
      params = params_for(:receipt, logs: [log_params])
      changeset = Receipt.changeset(%Receipt{}, params)
      receipt = Repo.insert!(changeset) |> Repo.preload(logs: :address)
      assert List.first(receipt.logs).address == address
    end
  end
end
