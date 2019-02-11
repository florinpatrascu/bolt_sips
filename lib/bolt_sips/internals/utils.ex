defmodule Bolt.Sips.Internals.Utils do
  @moduledoc false

  # Different utils used to debugging and helping.

  @spec reduce_to_binary(Enum.t(), function()) :: binary()
  def reduce_to_binary(enumerable, transform) do
    Enum.reduce(enumerable, <<>>, fn data, acc -> acc <> transform.(data) end)
  end

  @spec hex_encode(String.t()) :: [binary()]
  def hex_encode(bytes) do
    for <<i <- bytes>>, do: Integer.to_string(i, 16)
  end

  @spec hex_decode(binary()) :: String.t()
  def hex_decode(hex_list) do
    integers = for(hex <- hex_list, do: hex |> Integer.parse(16) |> elem(0))
    reduce_to_binary(integers, &<<&1>>)
  end
end
