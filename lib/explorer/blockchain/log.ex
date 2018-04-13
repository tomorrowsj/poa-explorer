defmodule Explorer.Blockchain.Log do
  @moduledoc """
  TODO
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Explorer.Blockchain.{Receipt, Log}

  @required_attrs ~w(index data type)a
  @optional_attrs ~w(
    first_topic second_topic third_topic fourth_topic address_id
  )a

  schema "logs" do
    field :index, :integer
    field :data, :string
    field :type, :string
    field :first_topic, :string
    field :second_topic, :string
    field :third_topic, :string
    field :fourth_topic, :string

    belongs_to :receipt, Receipt
    has_one :transaction, through: [:receipt, :transaction]
    # belongs_to(:address, Address)

    timestamps()
  end

  def changeset(%Log{} = log, attrs \\ %{}) do
    log
    |> cast(attrs, @required_attrs)
    |> cast(attrs, @optional_attrs)
    |> cast_assoc(:address)
    |> cast_assoc(:receipt)
    |> validate_required(@required_attrs)
  end
end