defprotocol Bolt.Sips.Internals.PackStream.Encoder do
  @moduledoc false

  # Encodes an item to its binary PackStream Representation
  #
  # Implementation exists for following types:
  #   - Integer
  #   - Float
  #   - List
  #   - Map
  #   - Struct (defined in the Bolt protocol)

  @fallback_to_any true

  def encode(entitiy)
end

defimpl Bolt.Sips.Internals.PackStream.Encoder, for: Atom do
  @null_marker 0xC0
  @true_marker 0xC3
  @false_marker 0xC2

  @doc "Encode Integer"
  @spec encode(atom()) :: Bolt.Sips.Internals.PackStream.value()
  def encode(nil), do: <<@null_marker>>
  def encode(true), do: <<@true_marker>>
  def encode(false), do: <<@false_marker>>

  def encode(other) when is_atom(other) do
    other
    |> Atom.to_string()
    |> Bolt.Sips.Internals.PackStream.Encoder.encode()
  end
end

defimpl Bolt.Sips.Internals.PackStream.Encoder, for: Integer do
  @int8_marker 0xC8
  @int16_marker 0xC9
  @int32_marker 0xCA
  @int64_marker 0xCB

  @int8 -127..-17
  @int16_low -32_768..-129
  @int16_high 128..32_767
  @int32_low -2_147_483_648..-32_769
  @int32_high 32_768..2_147_483_647
  @int64_low -9_223_372_036_854_775_808..-2_147_483_649
  @int64_high 2_147_483_648..9_223_372_036_854_775_807

  @spec encode(integer()) :: Bolt.Sips.Internals.PackStream.value()
  def encode(integer) when integer in -16..127 do
    <<integer>>
  end

  def encode(integer) when integer in @int8 do
    <<@int8_marker, integer>>
  end

  def encode(integer) when integer in @int16_low or integer in @int16_high do
    <<@int16_marker, integer::16>>
  end

  def encode(integer) when integer in @int32_low or integer in @int32_high do
    <<@int32_marker, integer::32>>
  end

  def encode(integer) when integer in @int64_low or integer in @int64_high do
    <<@int64_marker, integer::64>>
  end
end

defimpl Bolt.Sips.Internals.PackStream.Encoder, for: Float do
  @float_marker 0xC1

  @spec encode(float()) :: Bolt.Sips.Internals.PackStream.value()
  def encode(number) do
    <<@float_marker, number::float>>
  end
end

defimpl Bolt.Sips.Internals.PackStream.Encoder, for: BitString do
  @tiny_bitstring_marker 0x8
  @bitstring8_marker 0xD0
  @bitstring16_marker 0xD1
  @bitstring32_marker 0xD2

  @spec encode(String.t()) :: Bolt.Sips.Internals.PackStream.value()
  def encode(string), do: do_encode(string, byte_size(string))

  @spec do_encode(String.t(), integer()) :: Bolt.Sips.Internals.PackStream.value()
  defp do_encode(string, size) when size <= 15 do
    <<@tiny_bitstring_marker::4, size::4>> <> string
  end

  defp do_encode(string, size) when size <= 255 do
    <<@bitstring8_marker, size::8>> <> string
  end

  defp do_encode(string, size) when size <= 65_535 do
    <<@bitstring16_marker, size::16>> <> string
  end

  defp do_encode(string, size) when size <= 4_294_967_295 do
    <<@bitstring32_marker, size::32>> <> string
  end
end

defimpl Bolt.Sips.Internals.PackStream.Encoder, for: List do
  @tiny_list_marker 0x9
  @list8_marker 0xD4
  @list16_marker 0xD5
  @list32_marker 0xD6

  @spec encode([term()]) :: Bolt.Sips.Internals.PackStream.value()
  def encode(list) do
    binary = Enum.map_join(list, &Bolt.Sips.Internals.PackStream.Encoder.encode/1)

    do_encode(binary, length(list))
  end

  @spec do_encode(binary(), integer()) :: Bolt.Sips.Internals.PackStream.value()
  defp do_encode(binary, list_size) when list_size <= 15 do
    <<@tiny_list_marker::4, list_size::4>> <> binary
  end

  defp do_encode(binary, list_size) when list_size <= 255 do
    <<@list8_marker, list_size::8>> <> binary
  end

  defp do_encode(binary, list_size) when list_size <= 65_535 do
    <<@list16_marker, list_size::16>> <> binary
  end

  defp do_encode(binary, list_size) when list_size <= 4_294_967_295 do
    <<@list32_marker, list_size::32>> <> binary
  end
end

defimpl Bolt.Sips.Internals.PackStream.Encoder, for: Map do
  @tiny_map_marker 0xA
  @map8_marker 0xD8
  @map16_marker 0xD9
  @map32_marker 0xDA

  @spec encode(map()) :: Bolt.Sips.Internals.PackStream.value()
  def encode(map) do
    do_encode(map, map_size(map))
  end

  @spec do_encode(map(), integer) :: Bolt.Sips.Internals.PackStream.value()
  defp do_encode(map, size) when size <= 15 do
    <<@tiny_map_marker::4, size::4>> <> encode_kv(map)
  end

  defp do_encode(map, size) when size <= 255 do
    <<@map8_marker, size::8>> <> encode_kv(map)
  end

  defp do_encode(map, size) when size <= 65_535 do
    <<@map16_marker, size::16>> <> encode_kv(map)
  end

  defp do_encode(map, size) when size <= 4_294_967_295 do
    <<@map32_marker, size::32>> <> encode_kv(map)
  end

  @spec encode_kv(map()) :: binary()
  defp encode_kv(map) do
    Bolt.Sips.Internals.Utils.reduce_to_binary(map, &do_reduce_kv/1)
  end

  @spec do_reduce_kv({atom(), term()}) :: binary()
  defp do_reduce_kv({key, value}) do
    Bolt.Sips.Internals.PackStream.Encoder.encode(key) <>
      Bolt.Sips.Internals.PackStream.Encoder.encode(value)
  end
end

defimpl Bolt.Sips.Internals.PackStream.Encoder, for: Any do
  @tiny_struct_marker 0xB
  @struct8_marker 0xDC
  @struct16_marker 0xDD

  @valid_signatures 0..127

  @spec encode({integer(), %{:__struct__ => String.t()} | list()}) ::
          Bolt.Sips.Internals.PackStream.value() | <<_::16, _::_*8>>
  def encode({signature, %{__struct__: _} = data}) when signature in @valid_signatures do
    do_encode(data, signature)
  end

  def encode({signature, data}) when signature in @valid_signatures and is_list(data) do
    do_encode(data, signature)
  end

  def encode(%{__struct__: _} = data) do
    encode_struct_map(data)
  end

  def encode(item) do
    raise Bolt.Sips.Internals.PackStream.EncodeError, item: item
  end

  # Unordered structs
  # For this kind of structs, a Map is provided
  @spec do_encode(map() | list(), integer()) ::
          Bolt.Sips.Internals.PackStream.value() | <<_::16, _::_*8>>
  defp do_encode(map, signature) when is_map(map) and map_size(map) < 16 do
    <<@tiny_struct_marker::4, map_size(map)::4, signature>> <> encode_struct_map(map)
  end

  defp do_encode(map, signature) when is_map(map) and map_size(map) < 256 do
    <<@struct8_marker::8, map_size(map)::8, signature>> <> encode_struct_map(map)
  end

  defp do_encode(map, signature) when is_map(map) and map_size(map) < 65_535 do
    <<@struct16_marker::8, map_size(map)::16, signature>> <> encode_struct_map(map)
  end

  # Ordered structs
  # For this kind of structs, a List is provided
  # Typically, message will be ordered struct
  defp do_encode(list, signature) when is_list(list) and length(list) < 16 do
    <<@tiny_struct_marker::4, length(list)::4, signature>> <> encode_struct_list(list)
  end

  defp do_encode(list, signature) when is_list(list) and length(list) < 256 do
    <<@struct8_marker::8, length(list)::8, signature>> <> encode_struct_list(list)
  end

  defp do_encode(list, signature) when is_list(list) and length(list) < 65_535 do
    <<@struct16_marker::8, length(list)::16, signature>> <> encode_struct_list(list)
  end

  @spec encode_struct_map(map()) :: Bolt.Sips.Internals.PackStream.value()
  defp encode_struct_map(data) do
    data
    |> Map.from_struct()
    |> Bolt.Sips.Internals.PackStream.Encoder.encode()
  end

  @spec encode_struct_map(list()) :: Bolt.Sips.Internals.PackStream.value()
  defp encode_struct_list(data) do
    data
    |> Enum.map_join("", &Bolt.Sips.Internals.PackStream.Encoder.encode/1)
  end
end
