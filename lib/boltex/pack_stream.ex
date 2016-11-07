defmodule Boltex.PackStream do
  @moduledoc """
  The PackStream implementation for Bolt.

  This module defines a decode function, that will take a binary stream of data
  and recursively turn it into a list of Elixir data types.

  It further defines a function for encoding Elixir data types into a binary
  stream, using the Boltex.PackStream.Encoder protocol.
  """

  @doc """
  Encodes a list of items into their binary representation.

  As developers tend to be lazy, single objects may be passed.

  ## Examples

      iex> Boltex.PackStream.encode "hello world"
      <<0x8B, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x77, 0x6F, 0x72, 0x6C, 0x64>>
  """
  def encode(item), do: Boltex.PackStream.Encoder.encode(item)

  ##
  # Decode
  @doc "Decodes a binary stream recursively into Elixir data types"
  # Null
  def decode(<< 0xC0, rest :: binary >>), do: [nil| decode(rest)]

  # Boolean
  def decode(<< 0xC3, rest :: binary >>), do: [true  | decode(rest)]
  def decode(<< 0xC2, rest :: binary >>), do: [false | decode(rest)]

  # Float
  def decode(<< 0xC1, number :: float, rest :: binary >>) do
    [number | decode(rest)]
  end

  # Strings
  def decode(<< 0x8 :: 4, str_length :: 4, rest :: bytes >>) do
    decode_text rest, str_length
  end
  def decode(<< 0xD0, str_length, rest :: bytes >>) do
    decode_text rest, str_length
  end
  def decode(<< 0xD1, str_length :: 16, rest :: bytes >>) do
    decode_text rest, str_length
  end
  def decode(<< 0xD2, str_length :: 32, rest :: binary >>) do
    decode_text rest, str_length
  end

  # Lists
  def decode(<< 0x9 :: 4, list_size :: 4  >> <> bin), do: list(bin, list_size)
  def decode(<< 0xD4,     list_size :: 8  >> <> bin), do: list(bin, list_size)
  def decode(<< 0xD5,     list_size :: 16 >> <> bin), do: list(bin, list_size)
  def decode(<< 0xD6,     list_size :: 32 >> <> bin), do: list(bin, list_size)
  def decode(<< 0xD7 >> <> bin) do
    bytes    = for(<< byte <- bin >>, do: byte)
    position = Enum.find_index bytes, &(&1 == 0xDF)

    << list :: binary-size(position), 0xDF, rest :: binary >> = bin

    [decode(list) | decode(rest)]
  end

  # Maps
  def decode(<< 0xA :: 4, entries :: 4 >>  <> bin), do: map(bin, entries)
  def decode(<< 0xD8,     entries :: 8 >>  <> bin), do: map(bin, entries)
  def decode(<< 0xD9,     entries :: 16 >> <> bin), do: map(bin, entries)
  def decode(<< 0xDA,     entries :: 32 >> <> bin), do: map(bin, entries)
  def decode(<< 0xDB >> <> bin) do
    bytes    = for(<< byte <- bin >>, do: byte)
    position = Enum.find_index bytes, &(&1 == 0xDF)

    << map:: binary-size(position), 0xDF, rest :: binary >> = bin

    (map |> decode |> to_map) ++ decode(rest)
  end

  # Struct
  def decode(<< 0xB :: 4, struct_size :: 4, sig :: 8>> <> struct) do
    {struct, rest} = struct |> decode |> Enum.split(struct_size)

    [[sig: sig, fields: struct] | rest]
  end

  def decode(<<0, 0>>), do: []
  def decode(""), do: []

  # Integers
  def decode(<< 0xC8, int, rest :: binary >>),       do: [int | decode(rest)]
  def decode(<< 0xC9, int :: 16, rest :: binary >>), do: [int | decode(rest)]
  def decode(<< 0xCA, int :: 32, rest :: binary >>), do: [int | decode(rest)]
  def decode(<< 0xCB, int :: 64, rest :: binary >>), do: [int | decode(rest)]
  def decode(<< int, rest :: binary >>),             do: [int | decode(rest)]

  defp decode_text(bytes, str_length) do
    << string :: binary-size(str_length), rest :: binary >> = bytes

    [string | decode(rest)]
  end

  defp map(map, entries) do
    {map, rest} = map |> decode |> Enum.split(entries * 2)

    [to_map(map) | rest]
  end
  defp to_map(map) do
    map
    |> Enum.chunk(2)
    |> Enum.map(&List.to_tuple/1)
    |> Map.new
  end

  defp list(list, list_size) do
    {list, rest} = list |> decode |> Enum.split(list_size)
    [list | rest]
  end
end
