defmodule Explorer.Servers.Chain do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %Explorer.Chain{})
  end
end
