defmodule Explorer.Importers.BlockTest do
  alias Explorer.Block
  alias Explorer.Importers.Block, as: Importer

  use Explorer.DataCase

  describe "import/1" do
    test "formats web3 block data as a Block" do
      block = Importer.import(%{
        "difficulty" => "0x0000000FF1CE",
        "gasLimit" => "0x00BAB10C",
        "gasUsed" => "0x1BADB002",
        "hash" => "0x4B1D",
        "miner" => "0xB105F00D",
        "nonce" => nil,
        "number" => "0xBAAAAAAD",
        "parentHash" => "0xBAADF00D",
        "size" => "0xBAD22222",
        "timestamp" => "0xC00010FF",
        "totalDifficulty" => "0xBADDCAFE",
        "transactions" => []
      })
      assert block.changes == %Block{
        difficulty: 1044942,
        gas_limit: 12235020,
        gas_used: 464367618,
        hash: "0x4B1D",
        miner: "0xB105F00D",
        nonce: "0",
        number: 3131746989,
        parent_hash: "0xBAADF00D",
        size: 3134333474,
        timestamp: Timex.from_unix(3221229823),
        total_difficulty: 3135097598
      }
    end
  end
end
