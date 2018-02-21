defmodule Explorer.EthereumexExtensions do
  @moduledoc false

  alias Ethereumex.HttpClient

  def trace_transaction(hash) do
    params = [hash, ["trace"]]
    HttpClient.request("trace_replayTransaction", params, [])
  end
end
