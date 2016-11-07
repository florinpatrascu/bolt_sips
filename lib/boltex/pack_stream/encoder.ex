defprotocol Boltex.PackStream.Encoder do
  @doc "Encodes an item to its binary PackStream Representation"
  def encode(entitiy)
end

defimpl Boltex.PackStream.Encoder, for: Atom do
  def encode(nil),   do: << 0xC0 >>
  def encode(true),  do: << 0xC3 >>
  def encode(false), do: << 0xC2 >>
  def encode(other) when is_atom(other) do
    other
    |> Atom.to_string
    |> Boltex.PackStream.Encoder.encode
  end
end

defimpl Boltex.PackStream.Encoder, for: Integer do
  @int8 -127..-17
  @int16_low  -32_768..-129
  @int16_high 128..32_767
  @int32_low  -2_147_483_648..-32_769
  @int32_high 32_768..2_147_483_647
  @int64_low  -9_223_372_036_854_775_808..-2_147_483_649
  @int64_high 2_147_483_648..9_223_372_036_854_775_807

  def encode(integer) when integer in -16..127 do
    <<integer>>
  end
  def encode(integer) when integer in @int8 do
    << 0xC8, integer >>
  end
  def encode(integer) when integer in @int16_low  or integer in @int16_high do
    << 0xC9, integer :: 16 >>
  end
  def encode(integer) when integer in @int32_low  or integer in @int32_high do
    << 0xCA, integer :: 32 >>
  end
  def encode(integer) when integer in @int64_low  or integer in @int64_high do
    << 0xCB, integer :: 64 >>
  end
end

defimpl Boltex.PackStream.Encoder, for: Float do
  def encode(number) do
    << 0xC1, number :: float>>
  end
end

defimpl Boltex.PackStream.Encoder, for: BitString do
  def encode(string), do: do_encode(string, byte_size(string))

  defp do_encode(string, size) when size <= 15 do
    << 0x8 :: 4, size :: 4 >> <> string
  end
  defp do_encode(string, size) when size <= 255 do
    << 0xD0, size :: 8 >> <> string
  end
  defp do_encode(string, size) when size <= 65_535 do
    << 0xD1, size :: 16 >> <> string
  end
  defp do_encode(string, size) when size <= 4_294_967_295 do
    << 0xD2, size :: 32 >> <> string
  end
end

defimpl Boltex.PackStream.Encoder, for: List do
  def encode(list) do
    binary = Enum.map_join list, &Boltex.PackStream.Encoder.encode/1

    do_encode binary, length(list)
  end

  defp do_encode(binary, list_size) when list_size <= 15 do
    << 0x9 :: 4, list_size :: 4 >> <> binary
  end
  defp do_encode(binary, list_size) when list_size <= 255 do
    << 0xD4, list_size :: 8 >> <> binary
  end
  defp do_encode(binary, list_size) when list_size <= 65_535 do
    << 0xD5, list_size :: 16 >> <> binary
  end
  defp do_encode(binary, list_size) when list_size <= 4_294_967_295 do
    << 0xD6, list_size :: 32 >> <> binary
  end
  defp do_encode(binary, _size) do
    << 0xD7 >> <> binary <> <<0xDF>>
  end
end

defimpl Boltex.PackStream.Encoder, for: Map do
  def encode(map) do
    do_encode map, map_size(map)
  end

  defp do_encode(map, size) when size <= 15 do
    << 0xA :: 4, size :: 4 >> <> encode_kv(map)
  end
  defp do_encode(map, size) when size <= 255 do
    << 0xD8, size :: 8 >> <> encode_kv(map)
  end
  defp do_encode(map, size) when size <= 65_535 do
    << 0xD9, size :: 16 >> <> encode_kv(map)
  end
  defp do_encode(map, size) when size <= 4_294_967_295 do
    << 0xDA, size :: 32 >> <> encode_kv(map)
  end

  defp encode_kv(map) do
    Boltex.Utils.reduce_to_binary map, &do_reduce_kv/1
  end

  defp do_reduce_kv({key, value}) do
    Boltex.PackStream.Encoder.encode(key) <>
    Boltex.PackStream.Encoder.encode(value)
  end
end
