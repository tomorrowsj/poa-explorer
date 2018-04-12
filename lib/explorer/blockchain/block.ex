defmodule Explorer.Blockchain.Block do
  @moduledoc """
  TODO
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Ecto.Changeset
  alias Explorer.Blockchain.{Block, Transaction}
  alias Explorer.ETH

  schema "blocks" do
    field :number, :integer
    field :hash, :string
    field :parent_hash, :string
    field :nonce, :string
    field :miner, :string
    field :difficulty, :decimal
    field :total_difficulty, :decimal
    field :size, :integer
    field :gas_limit, :integer
    field :gas_used, :integer
    field :timestamp, Timex.Ecto.DateTime

    timestamps()
  end

  @required_attrs ~w(number hash parent_hash nonce miner difficulty
                     total_difficulty size gas_limit gas_used timestamp)a

  @doc false
  def decode(raw_block) do
    raw_block
    |> decode_block()
    |> decode_transactions(raw_block["transactions"])
  end

  defp decode_block(raw_block) do
    attrs = %{
      hash: raw_block["hash"],
      number: ETH.decode_int_field(raw_block["number"]),
      gas_used: ETH.decode_int_field(raw_block["gasUsed"]),
      timestamp: ETH.decode_time_field(raw_block["timestamp"]),
      parent_hash: raw_block["parentHash"],
      miner: raw_block["miner"],
      difficulty: ETH.decode_int_field(raw_block["difficulty"]),
      total_difficulty: ETH.decode_int_field(raw_block["totalDifficulty"]),
      size: ETH.decode_int_field(raw_block["size"]),
      gas_limit: ETH.decode_int_field(raw_block["gasLimit"]),
      nonce: raw_block["nonce"] || "0",
    }

    case changeset(%Block{}, attrs) do
      %Changeset{valid?: true, changes: changes} -> {:ok, changes}
      %Changeset{valid?: false, errors: errors} -> {:error, {:block, errors}}
    end
  end

  defp decode_transactions({:ok, block_changes}, raw_transactions) do
    raw_transactions
    |> Enum.map(&Transaction.decode(&1))
    |> Enum.reduce_while({:ok, block_changes, []}, fn
      {:ok, trans_changes}, {:ok, block, acc} ->
        {:cont, {:ok, block, [trans_changes | acc]}}

      {:error, reason}, _ ->
        {:halt, {:error, {:transaction, reason}}}
    end)
  end
  defp decode_transactions({:error, reason}, _transactions), do: {:error, reason}

  defp changeset(%Block{} = block, attrs) do
    block
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
    |> update_change(:hash, &String.downcase/1)
  end
end
