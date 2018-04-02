defmodule Explorer.Indexer do
  @moduledoc """
  TODO
  """

  alias Explorer.Blockchain
  alias Explorer.Blockchain.Block

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {Explorer.Indexer.Supervisor, :start_link, [opts]},
      restart: :permanent,
      shutdown: 5000,
      type: :supervisor
    }
  end

  @doc """
  TODO
  """
  def last_indexed_block_number do
    case Blockchain.get_latest_block() do
      %Block{number: num} -> num
      nil -> 0
    end
  end
end
