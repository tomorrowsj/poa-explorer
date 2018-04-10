defmodule Explorer.Indexer.BlockFetcher do
  @moduledoc """
  TODO

  ## Next steps

  - after gensis index transition to RT index
  """
  use GenServer

  require Logger

  alias Explorer.{Indexer, Blockchain, ETH}
  alias Explorer.Indexer.Sequence

  defstruct ~w(current_block genesis_task subscription_id)a

  @batch_size 500
  @max_concurrency 25
  @polling_interval 20_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    send(self(), :index)
    :timer.send_interval(5_000, self(), :debug_count)

    {:ok, %__MODULE__{current_block: 0, genesis_task: nil, subscription_id: nil}}
  end

  def handle_info(:index, state) do
    {count, missing_ranges} = Blockchain.missing_block_numbers()
    current_block = Indexer.last_indexed_block_number()
    Logger.debug("#{count} missed block ranges between genesis and #{current_block}")

    {:ok, genesis_task} = Task.start_link(fn ->
      stream_import(missing_ranges, current_block)
    end)
    Process.monitor(genesis_task)

    {:noreply, %__MODULE__{state | genesis_task: genesis_task}}
  end

  def handle_info(:poll, %__MODULE__{subscription_id: subscription_id} = state) do
    Process.send_after(self(), :poll, @polling_interval)

    with {:ok, blocks} when length(blocks) > 0 <- ETH.check_for_updates(subscription_id) do
      Logger.debug(fn -> "Processing #{length(blocks)} new block(s)" end)

      # TODO do something with the new blocks
      ETH.fetch_blocks_by_hash(blocks)
    end

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, :normal}, %__MODULE__{genesis_task: pid} = state) do
    Logger.info(fn -> "Finished index from genesis" end)

    {:ok, subscription_id} = ETH.listen_for_new_blocks()

    send(self(), :poll)

    {:noreply, %__MODULE__{state | genesis_task: nil, subscription_id: subscription_id}}
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
      |> ETH.fetch_blocks_by_range(block_end)
      |> import_blocks(seq)
    end, max_concurrency: @max_concurrency, timeout: :infinity)
    |> Enum.each(fn {:ok, :ok} -> :ok end)
  end
  defp import_blocks({:ok, :end_of_chain, blocks, {_, block_end}}, seq) do
    Logger.info(fn -> "Reached end of blockchain #{inspect block_end}" end)
    :ok = Sequence.cap(seq)
    Blockchain.bulk_import(blocks)

    :ok
  end
  defp import_blocks({:ok, :more, blocks, {block_start, block_end}}, _seq) do
    Logger.debug(fn -> "got blocks #{block_start} - #{block_end}" end)
    Blockchain.bulk_import(blocks)

    :ok
  end
  defp import_blocks({:error, reason, range}, seq) do
    Logger.debug(fn -> "failed to fetch blocks #{inspect range}: #{inspect reason}. Retrying" end)
    :ok = Sequence.inject_range(seq, range)
  end
end
