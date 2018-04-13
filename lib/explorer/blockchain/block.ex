defmodule Explorer.Blockchain.Block do
  @moduledoc """
  TODO
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Ecto.Changeset
  alias Explorer.Blockchain.{Block, Transaction}

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
  def extract(raw_block, %{} = timestamps) do
    raw_block
    |> extract_block(timestamps)
    |> extract_transactions(raw_block["transactions"], timestamps)
  end

  defp extract_block(raw_block, %{} = timestamps) do
    attrs = %{
      hash: raw_block["hash"],
      number: raw_block["number"],
      gas_used: raw_block["gasUsed"],
      timestamp: raw_block["timestamp"],
      parent_hash: raw_block["parentHash"],
      miner: raw_block["miner"],
      difficulty: raw_block["difficulty"],
      total_difficulty: raw_block["totalDifficulty"],
      size: raw_block["size"],
      gas_limit: raw_block["gasLimit"],
      nonce: raw_block["nonce"] || "0",
    }

    case changeset(%Block{}, attrs) do
      %Changeset{valid?: true, changes: changes} -> {:ok, Map.merge(changes, timestamps)}
      %Changeset{valid?: false, errors: errors} -> {:error, {:block, errors}}
    end
  end

  defp extract_transactions({:ok, block_changes}, raw_transactions, %{} = timestamps) do
    raw_transactions
    |> Enum.map(&Transaction.decode(&1, block_changes.number, timestamps))
    |> Enum.reduce_while({:ok, block_changes, []}, fn
      {:ok, trans_changes}, {:ok, block, acc} ->
        {:cont, {:ok, block, [trans_changes | acc]}}

      {:error, reason}, _ ->
        {:halt, {:error, {:transaction, reason}}}
    end)
  end
  defp extract_transactions({:error, reason}, _transactions, _timestamps) do
    {:error, reason}
  end

  defp changeset(%Block{} = block, attrs) do
    block
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
    |> update_change(:hash, &String.downcase/1)
  end
end
