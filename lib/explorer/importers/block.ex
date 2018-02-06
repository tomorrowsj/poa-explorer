defmodule Explorer.Importers.Block do
  @moduledoc """
    Turns a ethereumex (web3) block into an Explorer.Block.
  """

  import Ecto.Changeset

  alias Explorer.Block

  @schema %{
    difficulty: Explorer.Importers.HexNumberType,
    gas_limit: Explorer.Importers.HexNumberType,
    gas_used: Explorer.Importers.HexNumberType,
    hash: :string,
    miner: :string,
    nonce: :string,
    number: Explorer.Importers.HexNumberType,
    parent_hash: :string,
    size: Explorer.Importers.HexNumberType,
    timestamp: Explorer.Importers.HexTimeType,
    total_difficulty: Explorer.Importers.HexNumberType
  }

  @mapping %{
    "difficulty" => :difficulty,
    "gasLimit" => :gas_limit,
    "gasUsed" => :gas_used,
    "hash" => :hash,
    "miner" => :miner,
    "nonce" => :nonce,
    "number" => :number,
    "parentHash" => :parent_hash,
    "size" => :size,
    "timestamp" => :timestamp,
    "totalDifficulty" => :total_difficulty
  }

  def import(params) do
    params
    |> remap(@mapping)
    |> cast(@schema)
    |> validate_required(Map.keys(@schema))
  end

  defp remap(params, mapping) do
    Enum.reduce(params, %{}, fn ({key, value}, memo) ->
      Map.put(memo, Map.get(mapping, key), value)
    end)
  end

  defp cast(params, schema) do
    changeset = {%{}, schema} |> Ecto.Changeset.cast(params, Map.keys(schema))
    put_in(changeset.changes, Map.merge(%Block{}, changeset.changes))
  end
end
