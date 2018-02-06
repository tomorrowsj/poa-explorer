defmodule Explorer.TransactionImporterTest do
  use Explorer.DataCase

  alias Explorer.Address
  alias Explorer.BlockTransaction
  alias Explorer.ToAddress
  alias Explorer.Transaction
  alias Explorer.TransactionImporter

  @raw_transaction %{
    "creates" => nil,
    "hash" => "pepino",
    "value" => "0xde0b6b3a7640000",
    "from" => "0x34d0ef2c",
    "gas" => "0x21000",
    "gasPrice" => "0x10000",
    "input" => "0x5c8eff12",
    "nonce" => "0x31337",
    "publicKey" => "0xb39af9c",
    "r" => "0x9",
    "s" => "0x10",
    "to" => "0x7a33b7d",
    "standardV" => "0x11",
    "transactionIndex" => "0x12",
    "v" => "0x13",
  }

  @processed_transaction %{
    hash: "pepino",
    value: 1000000000000000000,
    gas: 135168,
    gas_price: 65536,
    input: "0x5c8eff12",
    nonce: 201527,
    public_key: "0xb39af9c",
    r: "0x9",
    s: "0x10",
    standard_v: "0x11",
    transaction_index: "0x12",
    v: "0x13",
  }

  describe "import/1" do
    test "imports and saves a transaction to the database" do
      TransactionImporter.import("0xdc3a0dfd0bbffd5eabbe40fb13afbe35ac5f5c030bff148f3e50afe32974b291")
      transaction = Transaction |> order_by(desc: :inserted_at) |> Repo.one
      assert(transaction.hash == "0xdc3a0dfd0bbffd5eabbe40fb13afbe35ac5f5c030bff148f3e50afe32974b291")
    end

    test "when it has previously been saved it updates the transaction" do
      insert(:transaction, hash: "0x170baac4eca26076953370dd603c68eab340c0135b19b585010d3158a5dbbf23", gas: 5)
      TransactionImporter.import("0x170baac4eca26076953370dd603c68eab340c0135b19b585010d3158a5dbbf23")
      transaction = Transaction |> order_by(desc: :inserted_at) |> Repo.one
      assert(transaction.gas == Decimal.new(231855))
    end

    test "when it has a block hash that's saved in the database it saves the association" do
      block = insert(:block, hash: "0xfce13392435a8e7dab44c07d482212efb9dc39a9bea1915a9ead308b55a617f9")
      TransactionImporter.import("0x64d851139325479c3bb7ccc6e6ab4cde5bc927dce6810190fe5d770a4c1ac333")
      transaction = Transaction |> Repo.get_by(hash: "0x64d851139325479c3bb7ccc6e6ab4cde5bc927dce6810190fe5d770a4c1ac333")
      block_transaction = BlockTransaction |> Repo.get_by(transaction_id: transaction.id)
      assert block_transaction.block_id == block.id
    end

    test "when there is no block it does not save a block transaction" do
      use_cassette "transaction_importer_txn_without_block" do
        TransactionImporter.import("0xc6aa189827c14880f012a65292f7add7b5310094f8773a3d85b66303039b9dcf")
        transaction = Transaction |> Repo.get_by(hash: "0xc6aa189827c14880f012a65292f7add7b5310094f8773a3d85b66303039b9dcf")
        block_transaction = BlockTransaction |> Repo.get_by(transaction_id: transaction.id)
        refute block_transaction
      end
    end

    test "it creates a to address" do
      use_cassette "transaction_importer_creates_a_to_address" do
        TransactionImporter.import("0x111dcc7199ba1f967ec59eadd7831b465fc8860c93e8b909d5a54fda6f8378f5")

        transaction = Transaction |> Repo.get_by(hash: "0xc6aa189827c14880f012a65292f7add7b5310094f8773a3d85b66303039b9dcf")
        address = Address |> Repo.get_by(hash: "0x9d18dba6eb2755a06722c8b9f84d1f43ca1e102b") |> Repo.one
        to_address = ToAddress |> Repo.get_by(transaction_id: transaction.id, address_id: address.id)

        assert(to_address)
      end
    end

    test "it creates a from address" do
      # use_cassette "transaction_importer_creates_a_from_address" do
        TransactionImporter.import("0x111dcc7199ba1f967ec59eadd7831b465fc8860c93e8b909d5a54fda6f8378f5")

        transaction = Transaction |> Repo.get_by(hash: "0x111dcc7199ba1f967ec59eadd7831b465fc8860c93e8b909d5a54fda6f8378f5")
        address = Address |> Repo.get_by(hash: "0x23359b2330a82cca0618ffbc84cde3b760e69443") |> Repo.one
        from_address = FromAddress |> Repo.get_by(transaction_id: transaction.id, address_id: address.id)

        assert(from_address)
      # end
    end
  end

  describe "download_transaction/1" do
    test "downloads a transaction" do
      raw_transaction = TransactionImporter.download_transaction("0x170baac4eca26076953370dd603c68eab340c0135b19b585010d3158a5dbbf23")
      assert(raw_transaction["from"] == "0xbe96ef1d056c97323e210fd0dd818aa027e57143")
    end

    test "when the address is bad" do
      assert_raise MatchError, fn ->
        TransactionImporter.download_transaction("0xzzzzzzzzzzzzzz")
      end
    end
  end

  describe "extract_attrs/1" do
    test "returns a changeset-friendly list of transaction attributes" do
      transaction_attrs = TransactionImporter.extract_attrs(@raw_transaction)
      assert transaction_attrs == @processed_transaction
    end
  end

  describe "create_to_address/2" do
    test "that it creates a new address when one does not exist" do
      transaction = insert(:transaction)
      TransactionImporter.create_to_address(transaction, "0xFreshPrince")
      last_address = Address |> order_by(desc: :inserted_at) |> Repo.one
      assert last_address.hash == "0xfreshprince"
    end

    test "that it creates a relation for the transaction and address" do
      transaction = insert(:transaction)
      TransactionImporter.create_to_address(transaction, "0xFreshPrince")
      address = Address |> order_by(desc: :inserted_at) |> Repo.one
      to_address = ToAddress |> order_by(desc: :inserted_at)|> Repo.one
      assert to_address.transaction_id == transaction.id
      assert to_address.address_id == address.id
    end

    test "when the address already exists it doesn't insert a new address" do
      transaction = insert(:transaction)
      insert(:address, %{hash: "bigmouthbillybass"})
      TransactionImporter.create_to_address(transaction, "bigmouthbillybass")
      assert Address |> Repo.all |> length == 1
    end
  end

  describe "create_from_address/2" do
    test "that it creates a new address when one does not exist" do
      transaction = insert(:transaction)
      TransactionImporter.create_from_address(transaction, "0xbb8")
      last_address = Address |> order_by(desc: :inserted_at) |> Repo.one
      assert last_address.hash == "0xbb8"
    end

    test "that it creates a relation for the transaction and 'from address'" do
      block = insert(:block)
      TransactionImporter.create_transaction(block, @raw_transaction)
      transaction = Repo.get_by(Transaction, hash: "pepino")
      address = Repo.get_by(Address, hash: "0x34d0ef2c")
      assert Repo.get_by(FromAddress, %{transaction_id: transaction.id, address_id: address.id})
    end

    test "when the address already exists it doesn't insert a new address" do
      transaction = insert(:transaction)
      insert(:address, %{hash: "0xbb8"})
      TransactionImporter.create_from_address(transaction, "0xbb8")
      assert Address |> Repo.all |> length == 1
    end
  end

  describe "decode_integer_field/1" do
    test "returns the integer value of a hex value" do
      assert(TransactionImporter.decode_integer_field("0x7f2fb") == 520955)
    end
  end
end
