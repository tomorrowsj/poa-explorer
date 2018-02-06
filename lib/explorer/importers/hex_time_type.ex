defmodule Explorer.Importers.HexTimeType do
  @behaviour Ecto.Type
  def dump(number), do: Ecto.Type.dump(:utc_datetime, number)
  def load(number), do: Ecto.Type.load(:utc_datetime, number)
  def type, do: :utc_datetime
  def cast("0x" <> hex) when is_binary(hex) do
    hex
    |> String.to_integer(16)
    |> DateTime.from_unix
  end
  def cast(number), do: Ecto.Type.cast(:utc_datetime, number)
end
