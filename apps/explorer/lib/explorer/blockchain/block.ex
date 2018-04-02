defmodule Explorer.Blockchain.Block do
  @moduledoc """
  TODO
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Ecto.Changeset
  alias Explorer.Blockchain.Block

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
    attrs = %{
      hash: raw_block["hash"],
      number: decode_int_field(raw_block["number"]),
      gas_used: decode_int_field(raw_block["gasUsed"]),
      timestamp: decode_time_field(raw_block["timestamp"]),
      parent_hash: raw_block["parentHash"],
      miner: raw_block["miner"],
      difficulty: decode_int_field(raw_block["difficulty"]),
      total_difficulty: decode_int_field(raw_block["totalDifficulty"]),
      size: decode_int_field(raw_block["size"]),
      gas_limit: decode_int_field(raw_block["gasLimit"]),
      nonce: raw_block["nonce"] || "0",
    }

    %Block{}
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
    |> update_change(:hash, &String.downcase/1)
    |> case do
      %Changeset{valid?: true, changes: changes} -> {:ok, changes}
      %Changeset{valid?: false, errors: errors} -> {:error, errors}
    end
  end

  defp decode_int_field(hex) do
    {"0x", base_16} = String.split_at(hex, 2)
    String.to_integer(base_16, 16)
  end

  defp decode_time_field(field) do
    field |> decode_int_field() |> Timex.from_unix()
  end
end
