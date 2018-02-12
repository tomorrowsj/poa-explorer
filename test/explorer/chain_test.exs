defmodule Explorer.ChainTest do
  use Explorer.DataCase
  alias Explorer.Chain

  describe "fetch/0" do
    test "returns the highest block number" do
      block = insert(:block)
      chain = Chain.fetch()
      assert chain.number == block.number
    end

    test "returns the latest block timestamp" do
      block = insert(:block)
      chain = Chain.fetch()
      assert chain.timestamp == block.timestamp
    end

    test "returns the average time between blocks" do
      insert(:block, timestamp: 0 |> Timex.from_unix)
      insert(:block, timestamp: 50 |> Timex.from_unix)
      insert(:block, timestamp: 100 |> Timex.from_unix)
      chain = Chain.fetch()
      assert chain.average_time |> Timex.from_now() == "1 minute ago"
    end
  end
end
