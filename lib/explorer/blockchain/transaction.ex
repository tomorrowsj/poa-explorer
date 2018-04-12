defmodule Explorer.Blockchain.Transaction do
  @moduledoc "Models a Web3 transaction."

  use Explorer.Schema
  alias Ecto.Changeset

  # alias Explorer.Address
  # alias Explorer.BlockTransaction
  # alias Explorer.InternalTransaction
  # alias Explorer.Receipt
  alias Explorer.Blockchain.{Transaction, Block}
  alias Explorer.ETH

  schema "transactions" do
    # has_one(:receipt, Receipt)
    belongs_to(:block, Block)
    belongs_to(:from_address, Address)
    belongs_to(:to_address, Address)
    has_many(:internal_transactions, InternalTransaction)
    field(:hash, :string)
    field(:value, :decimal)
    field(:gas, :decimal)
    field(:gas_price, :decimal)
    field(:input, :string)
    field(:nonce, :integer)
    field(:public_key, :string)
    field(:r, :string)
    field(:s, :string)
    field(:standard_v, :string)
    field(:transaction_index, :string)
    field(:v, :string)
    timestamps()
  end

  @required_attrs ~w(hash value gas gas_price input nonce public_key r s
    standard_v transaction_index v)a

  @optional_attrs ~w(to_address_id from_address_id)a

  @doc false
  def changeset(%Transaction{} = transaction, attrs \\ %{}) do
    transaction
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> foreign_key_constraint(:block_id)
    |> update_change(:hash, &String.downcase/1)
    |> unique_constraint(:hash)
  end

  def decode(raw_transaction) do
    attrs = %{
      hash: raw_transaction["hash"],
      value: raw_transaction["value"] |> ETH.decode_int_field(),
      gas: raw_transaction["gas"] |> ETH.decode_int_field(),
      gas_price: raw_transaction["gasPrice"] |> ETH.decode_int_field(),
      input: raw_transaction["input"],
      nonce: raw_transaction["nonce"] |> ETH.decode_int_field(),
      public_key: raw_transaction["publicKey"],
      r: raw_transaction["r"],
      s: raw_transaction["s"],
      standard_v: raw_transaction["standardV"],
      transaction_index: raw_transaction["transactionIndex"],
      v: raw_transaction["v"]
    }

    case changeset(%Transaction{}, attrs) do
      %Changeset{valid?: true, changes: changes} -> {:ok, changes}
      %Changeset{valid?: false, errors: errors} -> {:error, errors}
    end
  end

  def null, do: %Transaction{}
end
