defmodule Explorer.Address do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Explorer.Address

  @timestamps_opts [type: Timex.Ecto.DateTime,
                    autogenerate: {Timex.Ecto.DateTime, :autogenerate, []}]

  schema "addresses" do
    field :hash, :string
    timestamps()
  end

  @required_attrs ~w(hash)a
  @optional_attrs ~w()a

  def changeset(%Address{} = address, attrs) do
    address
    |> cast(attrs, @required_attrs, @optional_attrs)
    |> validate_required(@required_attrs)
    |> update_change(:hash, &String.downcase/1)
    |> unique_constraint(:hash)
  end
end
