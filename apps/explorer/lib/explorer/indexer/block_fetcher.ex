defmodule Explorer.Indexer.BlockFetcher do
  use GenServer
  @moduledoc """
  TODO

  ## Next steps

  - after gensis index transition to RT index
  """
  require Logger

  alias Explorer.{Indexer, Blockchain, ETH}
  alias Explorer.Indexer.Sequence

  @batch_size 500
  @max_concurrency 25

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    send(self(), :index)
    :timer.send_interval(5_000, self(), :debug_count)

    {:ok, %{current_block: 0, genesis_task: nil}}
  end

  def handle_info(:index, state) do
    {count, missing_ranges} = Blockchain.missing_block_numbers()
    current_block = Indexer.last_indexed_block_number()
    Logger.debug("#{count} missed block ranges between genesis and #{current_block}")

    {:ok, genesis_task} = Task.start_link(fn ->
      stream_import(missing_ranges, current_block)
    end)
    Process.monitor(genesis_task)

    {:noreply, %{state | genesis_task: genesis_task}}
  end

  def handle_info({:DOWN, _ref, :process, pid, :normal}, %{genesis_task: pid} = state) do
    Logger.info("Finished index from genesis")
    {:noreply, %{state | genesis_task: nil}}
  end

  def handle_info(:debug_count, state) do
    Logger.debug(fn -> "persisted blocks: #{Blockchain.block_count()}" end)
    {:noreply, state}
  end

  defp stream_import(missing_ranges, current_block) do
    {:ok, seq} = Sequence.start_link(missing_ranges, current_block, @batch_size)

    seq
    |> Sequence.build_stream()
    |> Task.async_stream(fn {block_start, block_end} ->
      block_start
      |> ETH.fetch_blocks(block_end)
      |> import_blocks(seq)
    end, max_concurrency: @max_concurrency, timeout: :infinity)
    |> Enum.each(fn {:ok, :ok} -> :ok end)
  end
  defp import_blocks({:ok, :end_of_chain, blocks, {_, block_end}}, seq) do
    Logger.info("Reached end of blockchain #{inspect block_end}")
    :ok = Sequence.cap(seq)
    Blockchain.bulk_import(blocks)

    :ok
  end
  defp import_blocks({:ok, :more, blocks, {block_start, block_end}}, _seq) do
    Logger.debug("got blocks #{block_start} - #{block_end}")
    Blockchain.bulk_import(blocks)

    :ok
  end
  defp import_blocks({:error, reason, range}, seq) do
    Logger.debug("failed to fetch blocks #{inspect range}: #{inspect reason}. Retrying")
    :ok = Sequence.inject_range(seq, range)
  end
end
