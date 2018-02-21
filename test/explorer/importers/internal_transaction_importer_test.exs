defmodule Explorer.InternalTransactionImporterTest do
  use Explorer.DataCase

  alias Explorer.InternalTransaction
  alias Explorer.InternalTransactionImporter

  describe "import/1" do
    test "imports and saves an internal transaction to the database" do
      use_cassette "internal_transaction_importer_import_1_from_core-trace" do
        hash = "0xc8d9053a4e07e6ca8e8490257312c79521af2d40824291ababd268d28f0a21eb"
        InternalTransactionImporter.import(hash)
        internal_transactions = InternalTransaction |> Repo.all

        assert length(internal_transactions) == 20
      end
    end
  end
end
