defmodule Bolt.Sips.Internals.PackStream.DecoderV1 do
  @moduledoc """
  Bolt V1 can decode:
  - Null
  - Boolean
  - Integer
  - Float
  - String
  - List
  - Map
  - Struct
  """
  use Bolt.Sips.Internals.PackStream.Markers
  alias Bolt.Sips.Internals.PackStream.Decoder

  @spec decode(binary(), integer()) :: list() | {:error, :not_implemented}
  def decode(<<@null_marker, rest::binary>>, bolt_version) do
    [nil | Decoder.decode(rest, bolt_version)]
  end

  # Boolean
  def decode(<<@true_marker, rest::binary>>, bolt_version) do
    [true | Decoder.decode(rest, bolt_version)]
  end

  def decode(<<@false_marker, rest::binary>>, bolt_version) do
    [false | Decoder.decode(rest, bolt_version)]
  end

  # Float
  def decode(<<@float_marker, number::float, rest::binary>>, bolt_version) do
    [number | Decoder.decode(rest, bolt_version)]
  end

  # Strings
  def decode(<<@tiny_bitstring_marker::4, str_length::4, rest::bytes>>, bolt_version) do
    decode_string(rest, str_length, bolt_version)
  end

  def decode(<<@bitstring8_marker, str_length, rest::bytes>>, bolt_version) do
    decode_string(rest, str_length, bolt_version)
  end

  def decode(<<@bitstring16_marker, str_length::16, rest::bytes>>, bolt_version) do
    decode_string(rest, str_length, bolt_version)
  end

  def decode(<<@bitstring32_marker, str_length::32, rest::binary>>, bolt_version) do
    decode_string(rest, str_length, bolt_version)
  end

  # Lists
  def decode(<<@tiny_list_marker::4, list_size::4>> <> bin, bolt_version) do
    decode_list(bin, list_size, bolt_version)
  end

  def decode(<<@list8_marker, list_size::8>> <> bin, bolt_version) do
    decode_list(bin, list_size, bolt_version)
  end

  def decode(<<@list16_marker, list_size::16>> <> bin, bolt_version) do
    decode_list(bin, list_size, bolt_version)
  end

  def decode(<<@list32_marker, list_size::32>> <> bin, bolt_version) do
    decode_list(bin, list_size, bolt_version)
  end

  # Maps
  def decode(<<0xA::4, entries::4>> <> bin, bolt_version) do
    decode_map(bin, entries, bolt_version)
  end

  def decode(<<0xD8, entries::8>> <> bin, bolt_version) do
    decode_map(bin, entries, bolt_version)
  end

  def decode(<<0xD9, entries::16>> <> bin, bolt_version) do
    decode_map(bin, entries, bolt_version)
  end

  def decode(<<0xDA, entries::32>> <> bin, bolt_version) do
    decode_map(bin, entries, bolt_version)
  end

  # Struct
  def decode(<<0xB::4, struct_size::4, sig::8>> <> struct, bolt_version) do
    decode_struct(sig, struct, struct_size, bolt_version)
  end

  def decode(<<0xDC, struct_size::8, sig::8>> <> struct, bolt_version) do
    decode_struct(sig, struct, struct_size, bolt_version)
  end

  def decode(<<0xDD, struct_size::16, sig::8>> <> struct, bolt_version) do
    decode_struct(sig, struct, struct_size, bolt_version)
  end

  # Manage the end of data
  def decode("", _), do: []

  # Integers
  def decode(<<0xC8, int::signed-integer, rest::binary>>, bolt_version) do
    [int | Decoder.decode(rest, bolt_version)]
  end

  def decode(<<0xC9, int::signed-integer-16, rest::binary>>, bolt_version) do
    [int | Decoder.decode(rest, bolt_version)]
  end

  def decode(<<0xCA, int::signed-integer-32, rest::binary>>, bolt_version) do
    [int | Decoder.decode(rest, bolt_version)]
  end

  def decode(<<0xCB, int::signed-integer-64, rest::binary>>, bolt_version) do
    [int | Decoder.decode(rest, bolt_version)]
  end

  def decode(<<int::signed-integer, rest::binary>>, bolt_version) do
    [int | Decoder.decode(rest, bolt_version)]
  end

  def decode(_, _) do
    {:error, :not_implemented}
  end

  @spec decode_string(binary(), integer(), integer()) :: list()
  defp decode_string(bytes, str_length, bolt_version) do
    <<string::binary-size(str_length), rest::binary>> = bytes

    [string | Decoder.decode(rest, bolt_version)]
  end

  @spec decode_list(binary(), integer(), integer()) :: list()
  defp decode_list(list, list_size, bolt_version) do
    {list, rest} = list |> Decoder.decode(bolt_version) |> Enum.split(list_size)
    [list | rest]
  end

  @spec decode_map(binary(), integer(), integer()) :: list()
  defp decode_map(map, entries, bolt_version) do
    {map, rest} = map |> Decoder.decode(bolt_version) |> Enum.split(entries * 2)

    [to_map(map) | rest]
  end

  @spec to_map(list()) :: map()
  defp to_map(map) do
    map
    |> Enum.chunk_every(2)
    |> Enum.map(&List.to_tuple/1)
    |> Map.new()
  end

  @spec decode_struct(integer(), binary(), integer(), integer()) :: list()
  defp decode_struct(signature, struct, struct_size, bolt_version) do
    {struct, rest} = struct |> Decoder.decode(bolt_version) |> Enum.split(struct_size)

    [[sig: signature, fields: struct] | rest]
  end
end
