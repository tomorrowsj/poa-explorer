defmodule Explorer.Blockchain.InternalTransaction do
  @moduledoc """
  Schema for internal transactions.
  """

  use Explorer.Schema
  alias Explorer.Blockchain.{InternalTransaction, Transaction}
  alias Explorer.ETH

  schema "internal_transactions" do
    belongs_to(:transaction, Transaction)
    belongs_to(:from_address, Address)
    belongs_to(:to_address, Address)
    field(:to_address_hash, :string)
    field(:from_address_hash, :string)
    field(:index, :integer)
    field(:call_type, :string)
    field(:trace_address, {:array, :integer})
    field(:value, :decimal)
    field(:gas, :decimal)
    field(:gas_used, :decimal)
    field(:input, :string)
    field(:output, :string)
    field(:error, :string)
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


  def decode(trace) do
    %{
      index: 0, # TODO maybe provide index
      call_type: trace["action"]["callType"] || trace["type"],
      to_address_hash: to_address(trace),
      from_address_hash: trace |> from_address(),
      trace_address: trace["traceAddress"],
      value: trace["action"]["value"] |> ETH.decode_int_field(),
      gas: trace["action"]["gas"] |> ETH.decode_int_field(),
      gas_used: gas_used(trace),
      input: trace["action"]["input"],
      output: trace["result"]["output"],
      error: trace["error"],
    }
  end

  defp gas_used(%{"result" => %{"gasUsed" => gas}}), do: ETH.decode_int_field(gas)
  defp gas_used(%{"error" => _error}), do: 0

  defp to_address(%{"action" => %{"to" => address}})
       when not is_nil(address),
       do: address

  defp to_address(%{"result" => %{"address" => address}}), do: address
  defp to_address(%{"error" => _error}), do: nil

  defp from_address(%{"action" => %{"from" => address}}), do: address
end
