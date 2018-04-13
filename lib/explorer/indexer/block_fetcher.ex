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

  @batch_size 10
  @blocks_concurrency 4

  @receipts_batch_size 250
  @receipts_concurrency 10

  @internal_batch_size 50
  @internal_concurrency 2


  @doc """
  Ensures missing block number ranges are chunked into fetchable batches.
  """
  def missing_block_numbers do
    {count, missing_ranges} = Blockchain.missing_block_numbers()
    chunked_ranges =
      Enum.flat_map(missing_ranges, fn
        {start, ending} when ending - start <= @batch_size -> [{start, ending}]
        {start, ending} ->
          start
          |> Stream.iterate(&(&1 + @batch_size))
          |> Enum.reduce_while([], fn
            chunk_start, acc when chunk_start + @batch_size >= ending ->
              {:halt, [{chunk_start, ending} | acc]}
            chunk_start, acc ->
              {:cont, [{chunk_start, chunk_start + @batch_size - 1} | acc]}
          end)
          |> Enum.reverse()
      end)

    {count, chunked_ranges}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    send(self(), :index)
    :timer.send_interval(15_000, self(), :debug_count)

    {:ok, %{current_block: 0, genesis_task: nil}}
  end

  def handle_info(:index, state) do
    {count, missing_ranges} = missing_block_numbers()
    current_block = Indexer.last_indexed_block_number()

    Logger.debug(fn -> "#{count} missed block ranges between genesis and #{current_block}" end)

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
    Logger.debug(fn ->
      """

      ================================
      persisted counts
      ================================
        blocks: #{Blockchain.block_count()}
        internal transactions: #{Blockchain.internal_transaction_count()}
        receipts: #{Blockchain.receipt_count()}
        logs: #{Blockchain.log_count()}
      """
    end)
    {:noreply, state}
  end

  defp stream_import(missing_ranges, current_block) do
    {:ok, seq} = Sequence.start_link(missing_ranges, current_block, @batch_size)

    seq
    |> Sequence.build_stream()
    |> Task.async_stream(fn {block_start, block_end} = range ->
      with {:ok, next, blocks, range} <- ETH.fetch_blocks(block_start, block_end),
           :ok <- cap_seq(seq, next, range),
           transaction_hashes <- collect_transaction_hashes(blocks),
           {:ok, receipts} <- fetch_transaction_receipts(transaction_hashes),
           {:ok, internals} <- fetch_internal_transactions(transaction_hashes) do

        import_blocks(blocks, internals, receipts, seq, range)
      else
        {:error, reason} ->
          Logger.debug(fn -> "failed to fetch blocks #{inspect range}: #{inspect reason}. Retrying" end)
          :ok = Sequence.inject_range(seq, range)
      end
    end, max_concurrency: @blocks_concurrency, timeout: :infinity)
    |> Enum.each(fn {:ok, :ok} -> :ok end)
  end

  defp cap_seq(seq, :end_of_chain, {_block_start, block_end}) do
    Logger.info("Reached end of blockchain #{inspect block_end}")
    :ok = Sequence.cap(seq)
  end
  defp cap_seq(_seq, :more, {block_start, block_end}) do
    Logger.debug(fn -> "got blocks #{block_start} - #{block_end}" end)
    :ok
  end

  defp fetch_transaction_receipts([]), do: {:ok, %{}}
  defp fetch_transaction_receipts(hashes) do
    Logger.debug(fn -> "fetching #{length(hashes)} transaction receipts" end)
    stream_opts = [max_concurrency: @receipts_concurrency, timeout: :infinity]

    hashes
    |> Enum.chunk_every(@receipts_batch_size)
    |> Task.async_stream(&ETH.fetch_transaction_receipts(&1), stream_opts)
    |> Enum.reduce_while({:ok, %{}}, fn
      {:ok, {:ok, receipts}}, {:ok, acc} -> {:cont, {:ok, Map.merge(acc, receipts)}}
      {:ok, {:error, reason}}, {:ok, _acc} -> {:halt, {:error, reason}}
      {:error, reason}, {:ok, _acc} -> {:halt, {:error, reason}}
    end)
  end

  defp fetch_internal_transactions([]), do: {:ok, %{}}
  defp fetch_internal_transactions(hashes) do
    Logger.debug(fn -> "fetching #{length(hashes)} internal transactions" end)
    stream_opts = [max_concurrency: @internal_concurrency, timeout: :infinity]

    hashes
    |> Enum.chunk_every(@internal_batch_size)
    |> Task.async_stream(&ETH.fetch_internal_transactions(&1), stream_opts)
    |> Enum.reduce_while({:ok, %{}}, fn
      {:ok, {:ok, trans}}, {:ok, acc} -> {:cont, {:ok, Map.merge(acc, trans)}}
      {:ok, {:error, reason}}, {:ok, _acc} -> {:halt, {:error, reason}}
      {:error, reason}, {:ok, _acc} -> {:halt, {:error, reason}}
    end)
  end

  defp import_blocks(blocks, internal_transactions, receipts, seq, range) do
    case Blockchain.import_blocks(blocks, internal_transactions, receipts) do
      {:ok, _results} -> :ok
      {:error, step, reason, _changes} ->
        Logger.debug(fn -> "failed to insert blocks during #{step} #{inspect range}: #{inspect reason}. Retrying" end)
        :ok = Sequence.inject_range(seq, range)
    end
  end

  defp collect_transaction_hashes(raw_blocks) do
    Enum.flat_map(raw_blocks, fn %{"transactions" => transactions} ->
      Enum.map(transactions, fn %{"hash" => hash} -> hash end)
    end)
  end
end
