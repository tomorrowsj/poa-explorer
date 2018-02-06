defmodule Explorer.Importers.HexNumberType do
  @behaviour Ecto.Type
  def dump(number), do: Ecto.Type.dump(:decimal, number)
  def load(number), do: Ecto.Type.load(:decimal, number)
  def type, do: :decimal
  def cast("0x"<>hex) when is_binary(hex), do: {:ok, String.to_integer(hex, 16)}
  def cast(number), do: Ecto.Type.cast(:decimal, number)
end
