defmodule Explorer.Blockchain.InternalTransaction do
  @moduledoc """
  Schema for internal transactions.
  """

  use Explorer.Schema
  alias Explorer.Blockchain.{InternalTransaction, Transaction}

  schema "internal_transactions" do
    field :to_address_hash, :string
    field :from_address_hash, :string
    field :index, :integer
    field :call_type, :string
    field :trace_address, {:array, :integer}
    field :value, :decimal
    field :gas, :decimal
    field :gas_used, :decimal
    field :input, :string
    field :output, :string

    belongs_to :transaction, Transaction
    belongs_to :from_address, Address
    belongs_to :to_address, Address

    timestamps()
  end

  @required_attrs ~w(index call_type trace_address value gas gas_used
    transaction_id from_address_id to_address_id)a
  @optional_attrs ~w(input output)

  def changeset(%InternalTransaction{} = internal_transaction, attrs \\ %{}) do
    internal_transaction
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> foreign_key_constraint(:transaction_id)
    |> foreign_key_constraint(:to_address_id)
    |> foreign_key_constraint(:from_address_id)
    |> unique_constraint(:transaction_id, name: :internal_transactions_transaction_id_index_index)
  end


  def extract(trace, transaction_id, %{} = timestamps) do
    %{
      transaction_id: transaction_id,
      index: 0, # TODO maybe provide index
      call_type: trace["action"]["callType"] || trace["type"],
      to_address_hash: to_address(trace),
      from_address_hash: trace |> from_address(),
      trace_address: trace["traceAddress"],
      value: trace["action"]["value"],
      gas: trace["action"]["gas"],
      gas_used: gas_used(trace),
      input: trace["action"]["input"],
      output: trace["result"]["output"],
      # error: trace["error"],
      inserted_at: Map.fetch!(timestamps, :inserted_at),
      updated_at: Map.fetch!(timestamps, :updated_at),
    }
  end

  defp gas_used(%{"result" => %{"gasUsed" => gas}}), do: gas
  defp gas_used(%{"error" => _error}), do: 0

  defp to_address(%{"action" => %{"to" => address}})
       when not is_nil(address),
       do: address

  defp to_address(%{"result" => %{"address" => address}}), do: address
  defp to_address(%{"error" => _error}), do: nil

  defp from_address(%{"action" => %{"from" => address}}), do: address
end
