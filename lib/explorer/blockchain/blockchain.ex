defmodule Explorer.Blockchain do
  @moduledoc """
  TODO
  """

  import Ecto.Query
  alias Explorer.Repo
  alias Explorer.Blockchain.Block

  @doc """

  """
  def missing_block_numbers do
    {:ok, {_, missing_count, missing_ranges}} =
      Repo.transaction(fn ->
        from(b in Block, select: b.number, order_by: [asc: b.number])
        |> Repo.stream(max_rows: 1000)
        |> Enum.reduce({-1, 0, []}, fn
          num, {prev, missing_count, acc} when prev + 1 == num ->
            {num, missing_count, acc}
          num, {prev, missing_count, acc} ->
            {num, missing_count + (num - prev - 1), [{prev + 1, num - 1} | acc]}
        end)
      end)

    {missing_count, missing_ranges}
   end

  def block_count do
    Repo.one(from b in Block, select: count(b.id))
  end

  @doc """
  TODO
  """
  def get_latest_block do
    Repo.one(from(b in Block, limit: 1, order_by: [desc: b.number]))
  end

  @doc """
  TODO
  """
  def bulk_pre_import(raw_blocks) do
    blocks = decode_blocks(raw_blocks)
    Repo.insert_all(Block, blocks, on_conflict: :nothing)
  end


  @doc """
  TODO
  """
  def bulk_import(raw_blocks) do
    blocks = decode_blocks(raw_blocks)
    Repo.insert_all(Block, blocks, on_conflict: :nothing)
  end

  defp decode_blocks(raw_blocks) do
    now = Ecto.DateTime.utc()

    for raw_block <- raw_blocks do
      {:ok, block} = Block.decode(raw_block)
      Map.merge(block, %{inserted_at: now, updated_at: now})
    end
  end
end
