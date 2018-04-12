defmodule Explorer.Blockchain.Receipt do
  use Ecto.Schema
  import Ecto.Changeset

  alias Explorer.Blockchain.{Receipt, Transaction, Log}
  alias Explorer.ETH

  @required_attrs ~w(cumulative_gas_used gas_used status index)a
  @optional_attrs ~w(transaction_id)a

  schema "receipts" do
    belongs_to(:transaction, Transaction)
    has_many(:logs, Log)
    field(:cumulative_gas_used, :decimal)
    field(:gas_used, :decimal)
    field(:status, :integer)
    field(:index, :integer)
    timestamps()
  end

  def changeset(%Receipt{} = transaction_receipt, attrs \\ %{}) do
    transaction_receipt
    |> cast(attrs, @required_attrs)
    |> cast(attrs, @optional_attrs)
    |> cast_assoc(:transaction)
    |> cast_assoc(:logs)
    |> validate_required(@required_attrs)
    |> foreign_key_constraint(:transaction_id)
    |> unique_constraint(:transaction_id)
  end

  def decode(raw_receipts) do
    Enum.into(raw_receipts, %{}, fn {transaction_hash, raw_receipt} ->
      logs = Enum.map(Map.fetch!(raw_receipt, "logs"), &decode_log(&1))
      receipt = %{
        index: raw_receipt["transactionIndex"] |> ETH.decode_int_field(),
        cumulative_gas_used: raw_receipt["cumulativeGasUsed"] |> ETH.decode_int_field(),
        gas_used: raw_receipt["gasUsed"] |> ETH.decode_int_field(),
        status: raw_receipt["status"] |> ETH.decode_int_field(),
      }

      {transaction_hash, {receipt, logs}}
    end)
  end

  defp decode_log(log) do
    # address = Address.find_or_create_by_hash(log["address"])

    %{
      # address_id: 0, # TODO
      index: log["logIndex"] |> ETH.decode_int_field(),
      data: log["data"],
      type: log["type"],
      first_topic: log["topics"] |> Enum.at(0),
      second_topic: log["topics"] |> Enum.at(1),
      third_topic: log["topics"] |> Enum.at(2),
      fourth_topic: log["topics"] |> Enum.at(3)
    }
  end

end
