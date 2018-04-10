defmodule Explorer.ETH do
  @moduledoc """
  Ethereum JSONRPC client.
  """

  def child_spec(_opts) do
    :hackney_pool.child_spec(:eth, [
      recv_timeout: 60_000, timeout: 60_000, max_connections: 1000])
  end

  @doc """
  Creates a filter subscription that can be polled for retreiving new blocks.
  """
  def listen_for_new_blocks do
    id = DateTime.utc_now() |> DateTime.to_unix()
    request = build_request("eth_newBlockFilter", id)
    json_rpc(request)
  end


  @doc """
  Lists changes for a given filter subscription.
  """
  def check_for_updates(filter_id) do
    request = build_request("eth_getFilterChanges", filter_id, filter_id)
    json_rpc(request)
  end

  @doc """
  Fetches blocks by block hashes.

  Transaction data is included for each block.
  """
  def fetch_blocks_by_hash(block_hashes) do
    batched_requests =
      for block_hash <- block_hashes do
        build_request("eth_getBlockByHash", block_hash, [block_hash, true])
      end

    json_rpc(batched_requests)
  end

  @doc """
  Fetches blocks by block number range.

  Transaction data is included for each block.
  """
  def fetch_blocks_by_range(block_start, block_end) do
    block_start
    |> build_batch_request(block_end)
    |> json_rpc()
    |> handle_batch_response(block_start, block_end)
  end
  defp build_batch_request(block_start, block_end) do
    for current <- block_start..block_end do
      build_request("eth_getBlockByNumber", current, [int_to_hash_string(current), false])
    end
  end
  defp handle_batch_response({:ok, results}, block_start, block_end) do
    {blocks, next} =
      Enum.reduce(results, {[], :more}, fn
        %{"result" => :null}, {blocks, _} -> {blocks, :end_of_chain}
        %{"result" => %{} = block}, {blocks, next} -> {[block | blocks], next}
      end)

    {:ok, next, blocks, {block_start, block_end}}
  end
  defp handle_batch_response({:error, reason}, block_start, block_end) do
    {:error, reason, {block_start, block_end}}
  end

  defp json_rpc(payload) do
    json = encode_json(payload)
    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post(config(:url), json, headers, config(:http)) do
      {:ok, %HTTPoison.Response{body: body, status_code: code}} ->
        body |> decode_json() |> handle_response(code)

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

  defp build_request(method, id, params_list \\ []) do
    %{
      "id" => id,
      "jsonrpc" => "2.0",
      "method" => method,
      "params" => List.wrap(params_list)
    }
  end

  defp config(key) do
    :explorer
    |> Application.fetch_env!(:eth_client)
    |> Keyword.fetch!(key)
  end

  defp encode_json(data), do: :jiffy.encode(data)

  defp decode_json(payload), do: :jiffy.decode(payload, [:return_maps])

  defp int_to_hash_string(number), do: "0x" <> Integer.to_string(number, 16)
end
