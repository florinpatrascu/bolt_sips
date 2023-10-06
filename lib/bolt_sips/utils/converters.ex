defmodule Bolt.Sips.Utils.Converters do
  def to_float(value) when is_float(value), do: value
  def to_float(value) when is_integer(value), do: value + 0.0
  def to_float(value) when is_bitstring(value) do
    case :string.to_float(value) do
      {:error, :no_float} -> integer_to_float(value)
      {num, _} -> num
    end
  end
  def to_float(_), do: {:error, "Could not convert to float"}
  defp integer_to_float(value) do
    case :string.to_integer(value) do
      {:error, :no_integer} -> {:error, "Could not convert to float"}
      {num, _} -> num + 0.0
    end
  end
end
