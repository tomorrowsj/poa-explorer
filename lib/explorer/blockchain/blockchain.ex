defmodule Explorer.Blockchain do
  @moduledoc """
  TODO
  """

  import Ecto.Query
  alias Ecto.Multi
  alias Explorer.Repo
  alias Explorer.Blockchain.{Block, Transaction, InternalTransaction, Receipt, Log}

  @doc """
  TODO
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

  def internal_transaction_count do
    Repo.one(from t in InternalTransaction, select: count(t.id))
  end

  def receipt_count do
    Repo.one(from r in Receipt, select: count(r.id))
  end

  def log_count do
    Repo.one(from l in Log, select: count(l.id))
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
  def import_blocks(raw_blocks, internal_transactions, receipts) do
    {blocks, transactions} = decode_blocks(raw_blocks)

    Multi.new()
    |> Multi.insert_all(:blocks, Block, blocks,
      returning: [:id, :number],
      on_conflict: :replace_all, conflict_target: :number)
    |> Multi.run(:transactions, &insert_transactions(&1, transactions))
    |> Multi.run(:internal, &insert_internal(&1, internal_transactions))
    |> Multi.run(:receipts, &insert_receipts(&1, receipts))
    |> Multi.run(:logs, &insert_logs(&1))
    |> Repo.transaction()
  end

  defp insert_transactions(%{blocks: {_, blocks}}, transactions) do
    blocks = for block <- blocks, into: %{}, do: {block.number, block}
    transactions = for transaction <- transactions do
      %{id: id} = Map.fetch!(blocks, transaction.block_number)

      transaction
      |> Map.put(:block_id, id)
      |> Map.delete(:block_number)
    end

    {_, inserted} = Repo.safe_insert_all(Transaction, transactions, returning: [:id, :hash])
    {:ok, inserted}
  end

  defp insert_internal(%{transactions: transactions}, internal_transactions) do
    timestamps = timestamps()

    internals = Enum.reduce(transactions, [], fn %{hash: hash, id: id}, acc ->
      case Map.fetch(internal_transactions, hash) do
        {:ok, traces} ->
          Enum.reduce(traces, acc, fn trace, acc ->
            decoded_trace =
              trace
              |> InternalTransaction.decode()
              |> Map.put(:transaction_id, id)
              |> Map.merge(timestamps)

            [decoded_trace | acc]
          end)

        :error -> acc
      end
    end)

    {_, inserted} = Repo.safe_insert_all(InternalTransaction, internals, on_conflict: :nothing)
    {:ok, inserted}
  end

  defp insert_receipts(%{transactions: transactions}, receipts) do
    timestamps = timestamps()

    receipts = Receipt.decode(receipts)
    {receipts_to_insert, logs_map} =
      Enum.reduce(transactions, {[], %{}}, fn trans, {receipts_acc, logs_acc} ->
        case Map.fetch(receipts, trans.hash) do
          {:ok, {receipt, logs}} ->
            receipt =
              receipt
              |> Map.merge(timestamps)
              |> Map.put(:transaction_id, trans.id)

            {[receipt | receipts_acc], Map.put(logs_acc, trans.id, logs)}

          :error ->
            {receipts_acc, logs_acc}
        end
      end)

    {_, inserted_receipts} =
      Repo.safe_insert_all(Receipt, receipts_to_insert, returning: [:id, :transaction_id])

    {:ok, %{inserted: inserted_receipts, logs: logs_map}}
  end

  defp insert_logs(%{receipts: %{inserted: receipts, logs: logs_map}}) do
    timestamps = timestamps()
    logs_to_insert =
      Enum.reduce(receipts, [], fn receipt, acc ->
        case Map.fetch(logs_map, receipt.transaction_id) do
          {:ok, []} -> acc
          {:ok, [_|_] = logs} ->
            logs = Enum.map(logs, fn log ->
              log
              |> Map.put(:receipt_id, receipt.id)
              |> Map.merge(timestamps)
            end)

            logs ++ acc
         end
      end)

    {_, inserted_logs} = Repo.safe_insert_all(Log, logs_to_insert, returning: [:id])
    {:ok, inserted_logs}
  end

  defp timestamps do
    now = Ecto.DateTime.utc()
    %{inserted_at: now, updated_at: now}
  end

  defp decode_blocks(raw_blocks) do
    timestamps = timestamps()

    {blocks, transactions} =
      Enum.reduce(raw_blocks, {[], []}, fn raw_block, {blocks_acc, trans_acc} ->
        {:ok, block, transactions} = Block.decode(raw_block)
        block = Map.merge(block, timestamps)
        trans_acc = Enum.reduce(transactions, trans_acc, fn transaction, acc ->
          transaction =
            transaction
            |> Map.put(:block_number, block.number)
            |> Map.merge(timestamps)

          [transaction | acc]
        end)

        {[block | blocks_acc], trans_acc}
      end)

    {Enum.reverse(blocks), Enum.reverse(transactions)}
  end
end
