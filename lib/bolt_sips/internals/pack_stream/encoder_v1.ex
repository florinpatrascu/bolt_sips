defmodule Bolt.Sips.Internals.PackStream.EncoderV1 do
  @moduledoc false
  alias Bolt.Sips.Internals.PackStream.Encoder
  use Bolt.Sips.Internals.PackStream.Markers

  @int8 -127..-17
  @int16_low -32_768..-129
  @int16_high 128..32_767
  @int32_low -2_147_483_648..-32_769
  @int32_high 32_768..2_147_483_647
  @int64_low -9_223_372_036_854_775_808..-2_147_483_649
  @int64_high 2_147_483_648..9_223_372_036_854_775_807

  @doc """
  Encode an atom into Bolt binary format.

  Encoding:
  `Marker`

  with

  | Value | Marker |
  | ------- | -------- |
  | nil | `0xC0` |
  | false | `0xC2` |
  | true | `0xC3` |

  Other atoms are converted to string before encoding.

  ## Example

      iex> alias Bolt.Sips.Internals.PackStream.EncoderV1
      iex> EncoderV1.encode_atom(nil, 1)
      <<0xC0>>
      iex> EncoderV1.encode_atom(true, 1)
      <<0xC3>>
      iex> EncoderV1.encode_atom(:guten_tag, 1)
      <<0x89, 0x67, 0x75, 0x74, 0x65, 0x6E, 0x5F, 0x74, 0x61, 0x67>>
  """
  @spec encode_atom(atom(), integer()) :: Bolt.Sips.Internals.PackStream.value()
  def encode_atom(nil, _bolt_version), do: <<@null_marker>>
  def encode_atom(true, _bolt_version), do: <<@true_marker>>
  def encode_atom(false, _bolt_version), do: <<@false_marker>>

  def encode_atom(other, bolt_version) do
    other |> Atom.to_string() |> encode_string(bolt_version)
  end

  @doc """
  Encode a string into Bolt binary format.

  Encoding:
  `Marker` `Size` `Content`

  with

  | Marker | Size | Max data size |
  |--------|------|---------------|
  | `0x80`..`0x8F` | None (contained in marker) | 15 bytes |
  | `0xD0` | 8-bit integer | 255 bytes |
  | `0xD1` | 16-bit integer | 65_535 bytes |
  | `0xD2` | 32-bit integer | 4_294_967_295 bytes |

  ## Example

      iex> alias Bolt.Sips.Internals.PackStream.EncoderV1
      iex> EncoderV1.encode_string("guten tag", 1)
      <<0x89, 0x67, 0x75, 0x74, 0x65, 0x6E, 0x20, 0x74, 0x61, 0x67>>
  """
  @spec encode_string(String.t(), integer()) :: Bolt.Sips.Internals.PackStream.value()
  def encode_string(string, _bolt_version) when byte_size(string) <= 15 do
    <<@tiny_bitstring_marker::4, byte_size(string)::4>> <> string
  end

  def encode_string(string, _bolt_version) when byte_size(string) <= 255 do
    <<@bitstring8_marker, byte_size(string)::8>> <> string
  end

  def encode_string(string, _bolt_version) when byte_size(string) <= 65_535 do
    <<@bitstring16_marker, byte_size(string)::16>> <> string
  end

  def encode_string(string, _bolt_version) when byte_size(string) <= 4_294_967_295 do
    <<@bitstring32_marker, byte_size(string)::32>> <> string
  end

  @doc """
  Encode an integer into Bolt binary format.

  Encoding:
  `Marker` `Value`

  with

  |   | Marker |
  |---|--------|
  | tiny int | `0x2A` |
  | int8 | `0xC8` |
  | int16 | `0xC9` |
  | int32 | `0xCA` |
  | int64 | `0xCB` |

  ## Example

      iex> alias Bolt.Sips.Internals.PackStream.EncoderV1
      iex> EncoderV1.encode_integer(74, 1)
      <<0x4A>>
      iex> EncoderV1.encode_integer(-74_789, 1)
      <<0xCA, 0xFF, 0xFE, 0xDB, 0xDB>>
  """
  @spec encode_integer(integer(), integer()) :: Bolt.Sips.Internals.PackStream.value()
  def encode_integer(integer, _bolt_version) when integer in -16..127 do
    <<integer>>
  end

  def encode_integer(integer, _bolt_version) when integer in @int8 do
    <<@int8_marker, integer>>
  end

  def encode_integer(integer, _bolt_version)
      when integer in @int16_low or integer in @int16_high do
    <<@int16_marker, integer::16>>
  end

  def encode_integer(integer, _bolt_version)
      when integer in @int32_low or integer in @int32_high do
    <<@int32_marker, integer::32>>
  end

  def encode_integer(integer, _bolt_version)
      when integer in @int64_low or integer in @int64_high do
    <<@int64_marker, integer::64>>
  end

  @doc """
  Encode a float into Bolt binary format.

  Encoding: `Marker` `8 byte Content`.

  Marker: `0xC1`

  Formated according to the IEEE 754 floating-point "double format" bit layout.

  ## Example

      iex> alias Bolt.Sips.Internals.PackStream.EncoderV1
      iex> EncoderV1.encode_float(42.42, 1)
      <<0xC1, 0x40, 0x45, 0x35, 0xC2, 0x8F, 0x5C, 0x28, 0xF6>>
  """
  @spec encode_float(float(), integer()) :: Bolt.Sips.Internals.PackStream.value()
  def encode_float(number, _bolt_version), do: <<@float_marker, number::float>>

  @doc """
  Encode a list into Bolt binary format.

  Encoding:
  `Marker` `Size` `Content`

  with

  | Marker | Size | Max list size |
  |--------|------|---------------|
  | `0x90`..`0x9F` | None (contained in marker) | 15 bytes |
  | `0xD4` | 8-bit integer | 255 items |
  | `0xD5` | 16-bit integer | 65_535 items |
  | `0xD6` | 32-bit integer | 4_294_967_295 items |

  ## Example

      iex> alias Bolt.Sips.Internals.PackStream.EncoderV1
      iex> EncoderV1.encode_list(["hello", "world"], 1)
      <<0x92, 0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x85, 0x77, 0x6F, 0x72, 0x6C, 0x64>>
  """
  @spec encode_list(list(), integer()) :: Bolt.Sips.Internals.PackStream.value()
  def encode_list(list, bolt_version) when length(list) <= 15 do
    <<@tiny_list_marker::4, length(list)::4>> <> encode_list_data(list, bolt_version)
  end

  def encode_list(list, bolt_version) when length(list) <= 255 do
    <<@list8_marker, length(list)::8>> <> encode_list_data(list, bolt_version)
  end

  def encode_list(list, bolt_version) when length(list) <= 65_535 do
    <<@list16_marker, length(list)::16>> <> encode_list_data(list, bolt_version)
  end

  def encode_list(list, bolt_version) when length(list) <= 4_294_967_295 do
    <<@list32_marker, length(list)::32>> <> encode_list_data(list, bolt_version)
  end

  @spec encode_list_data(list(), integer()) :: binary()
  defp encode_list_data(data, bolt_version) do
    Enum.map_join(data, &Encoder.encode(&1, bolt_version))
  end

  @doc """
  Encode a map into Bolt binary format.

  Note that Elixir structs are converted to map for encoding purpose.

  Encoding:
  `Marker` `Size` `Content`

  with

  | Marker | Size | Max map size |
  |--------|------|---------------|
  | `0xA0`..`0xAF` | None (contained in marker) | 15 entries |
  | `0xD8` | 8-bit integer | 255 entries |
  | `0xD9` | 16-bit integer | 65_535 entries |
  | `0xDA` | 32-bit integer | 4_294_967_295 entries |

  ## Example

      iex> alias Bolt.Sips.Internals.PackStream.EncoderV1
      iex> EncoderV1.encode_map(%{id: 345, value: "hello world"}, 1)
      <<0xA2, 0x82, 0x69, 0x64, 0xC9, 0x1, 0x59, 0x85, 0x76, 0x61, 0x6C, 0x75,
      0x65, 0x8B, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x77, 0x6F, 0x72, 0x6C, 0x64>>
  """
  @spec encode_map(map(), integer()) :: Bolt.Sips.Internals.PackStream.value()
  def encode_map(map, bolt_version) when map_size(map) <= 15 do
    <<@tiny_map_marker::4, map_size(map)::4>> <> encode_kv(map, bolt_version)
  end

  def encode_map(map, bolt_version) when map_size(map) <= 255 do
    <<@map8_marker, map_size(map)::8>> <> encode_kv(map, bolt_version)
  end

  def encode_map(map, bolt_version) when map_size(map) <= 65_535 do
    <<@map16_marker, map_size(map)::16>> <> encode_kv(map, bolt_version)
  end

  def encode_map(map, bolt_version) when map_size(map) <= 4_294_967_295 do
    <<@map32_marker, map_size(map)::32>> <> encode_kv(map, bolt_version)
  end

  @spec encode_kv(map(), integer()) :: binary()
  defp encode_kv(map, bolt_version) do
    Enum.reduce(map, <<>>, fn data, acc ->
      acc <> do_reduce_kv(data, bolt_version)
    end)
  end

  @spec do_reduce_kv({atom(), any()}, integer()) :: binary()
  defp do_reduce_kv({key, value}, bolt_version) do
    Encoder.encode(key, bolt_version) <> Encoder.encode(value, bolt_version)
  end

  @doc """
  Encode a struct into Bolt binary format.
  This concerns Bolt Structs as defined in []().
  Elixir structs are just converted to regular maps before encoding

  Encoding:
  `Marker` `Size` `Signature` `Content`

  with

  | Marker | Size | Max structure size |
  |--------|------|---------------|
  | `0xB0`..`0xBF` | None (contained in marker) | 15 fields |
  | `0xDC` | 8-bit integer | 255 fields |
  | `0xDD` | 16-bit integer | 65_535 fields |

  ## Example

      iex> alias Bolt.Sips.Internals.PackStream.EncoderV1
      iex> EncoderV1.encode_struct({0x01, ["two", "params"]}, 1)
      <<0xB2, 0x1, 0x83, 0x74, 0x77, 0x6F, 0x86, 0x70, 0x61, 0x72, 0x61, 0x6D, 0x73>>

  """
  @spec encode_struct({integer(), list()}, integer()) :: Bolt.Sips.Internals.PackStream.value()
  def encode_struct({signature, list}, bolt_version) when length(list) <= 15 do
    <<@tiny_struct_marker::4, length(list)::4, signature>> <> encode_list_data(list, bolt_version)
  end

  def encode_struct({signature, list}, bolt_version) when length(list) <= 255 do
    <<@struct8_marker::8, length(list)::8, signature>> <> encode_list_data(list, bolt_version)
  end

  def encode_struct({signature, list}, bolt_version) when length(list) <= 65_535 do
    <<@struct16_marker::8, length(list)::16, signature>> <> encode_list_data(list, bolt_version)
  end
end
