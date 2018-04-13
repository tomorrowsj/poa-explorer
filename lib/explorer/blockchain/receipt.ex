defmodule Explorer.Blockchain.Receipt do
  use Ecto.Schema
  import Ecto.Changeset

  alias Explorer.Blockchain.{Receipt, Transaction, Log}

  @required_attrs ~w(cumulative_gas_used gas_used status index)a
  @optional_attrs ~w(transaction_id)a

  schema "receipts" do
    field :cumulative_gas_used, :decimal
    field :gas_used, :decimal
    field :status, :integer
    field :index, :integer

    belongs_to :transaction, Transaction
    has_many :logs, Log

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

  def extract(raw_receipt, transaction_id, %{} = timestamps) do
    logs =
      raw_receipt
      |> Map.fetch!("logs")
      |> Enum.map(&extract_log(&1, timestamps))

    receipt = %{
      transaction_id: transaction_id,
      index: raw_receipt["transactionIndex"],
      cumulative_gas_used: raw_receipt["cumulativeGasUsed"],
      gas_used: raw_receipt["gasUsed"],
      status: raw_receipt["status"],
      inserted_at: Map.fetch!(timestamps, :inserted_at),
      updated_at: Map.fetch!(timestamps, :updated_at),
    }

    {receipt, logs}
  end

  defp extract_log(log, %{} = timestamps) do
    # address = Address.find_or_create_by_hash(log["address"])

    %{
      # address_id: 0, # TODO
      index: log["logIndex"],
      data: log["data"],
      type: log["type"],
      first_topic: log["topics"] |> Enum.at(0),
      second_topic: log["topics"] |> Enum.at(1),
      third_topic: log["topics"] |> Enum.at(2),
      fourth_topic: log["topics"] |> Enum.at(3),
      inserted_at: Map.fetch!(timestamps, :inserted_at),
      updated_at: Map.fetch!(timestamps, :updated_at),
    }
  end

end