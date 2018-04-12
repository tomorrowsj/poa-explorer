defmodule Explorer.ETH do
  @moduledoc """
  Ethereum JSONRPC client.
  """
  require Logger

  def child_spec(_opts) do
    :hackney_pool.child_spec(:eth, [
      recv_timeout: 60_000, timeout: 60_000, max_connections: 1000])
  end

  def decode_int_field(hex) do
    {"0x", base_16} = String.split_at(hex, 2)
    String.to_integer(base_16, 16)
  end

  def decode_time_field(field) do
    field |> decode_int_field() |> Timex.from_unix()
  end

  def fetch_transaction_receipts(hashes) when is_list(hashes) do
    hashes
    |> Enum.map(fn hash ->
      %{
        "id" => hash,
        "jsonrpc" => "2.0",
        "method" => "eth_getTransactionReceipt",
        "params" => [hash]
      }
    end)
    |> json_rpc(config(:url))
    |> handle_receipts()
  end
  defp handle_receipts({:ok, results}) do
    results_map =
      Enum.into(results, %{}, fn %{"id" => hash, "result" => receipt} ->
        {hash, receipt}
      end)

    {:ok, results_map}
  end
  defp handle_receipts({:error, reason}) do
    {:error, reason}
  end

  def fetch_internal_transactions(hashes) when is_list(hashes) do
    hashes
    |> Enum.map(fn hash ->
      %{
        "id" => hash,
        "jsonrpc" => "2.0",
        "method" => "trace_replayTransaction",
        "params" => [hash, ["trace"]]
      }
    end)
    |> json_rpc(config(:trace_url))
    |> handle_internal_transactions()
  end
  defp handle_internal_transactions({:ok, results}) do
    results_map =
      Enum.into(results, %{}, fn
        %{"error" => error} -> throw({:error, error})
        %{"id" => hash, "result" => %{"trace" => traces}} -> {hash, traces}
      end)

    {:ok, results_map}
  catch
    {:error, reason} -> {:error, reason}
  end
  defp handle_internal_transactions({:error, reason}) do
    {:error, reason}
  end

  @doc """
  TODO
  """
  def fetch_blocks(block_start, block_end) do
    block_start
    |> build_batch_get_block_by_number(block_end)
    |> json_rpc(config(:url))
    |> handle_get_block_by_number(block_start, block_end)
  end
  defp build_batch_get_block_by_number(block_start, block_end) do
    for current <- block_start..block_end do
      %{
        "id" => current,
        "jsonrpc" => "2.0",
        "method" => "eth_getBlockByNumber",
        "params" => [int_to_hash_string(current), true]
      }
    end
  end
  defp handle_get_block_by_number({:ok, results}, block_start, block_end) do
    {blocks, next} =
      Enum.reduce(results, {[], :more}, fn
        %{"result" => nil}, {blocks, _} -> {blocks, :end_of_chain}
        %{"result" => %{} = block}, {blocks, next} -> {[block | blocks], next}
      end)

    {:ok, next, blocks, {block_start, block_end}}
  end
  defp handle_get_block_by_number({:error, reason}, block_start, block_end) do
    {:error, reason, {block_start, block_end}}
  end

  defp json_rpc(payload, url) do
    json = encode_json(payload)
    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post(url, json, headers, config(:http)) do
      {:ok, %HTTPoison.Response{body: body, status_code: code}} ->
        body |> decode_json(payload) |> handle_response(code)

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp handle_response(resp, 200) do
    case resp do
      [%{} | _] = batch_resp -> {:ok, batch_resp}
      %{"error" => error} -> {:error, error}
      %{"result" => result} -> {:ok, result}
    end
  end
  defp handle_response(resp, _status) do
    {:error, resp}
  end

  defp config(key) do
    :explorer
    |> Application.fetch_env!(:eth_client)
    |> Keyword.fetch!(key)
  end

  defp encode_json(data), do: Jason.encode_to_iodata!(data)

  defp decode_json(body, posted_payload) do
    try do
      Jason.decode!(body)
    rescue
      Jason.DecodeError ->
        Logger.error """
        failed to decode json payload:

            #{inspect(body)}

            #{inspect(posted_payload)}

        """
        raise("bad jason")
    end
  end

  defp int_to_hash_string(number), do: "0x" <> Integer.to_string(number, 16)
end
