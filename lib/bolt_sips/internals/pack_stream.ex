defmodule Bolt.Sips.Internals.PackStream do
  @moduledoc false

  # The PackStream implementation for Bolt.
  #
  # This module defines a decode function, that will take a binary stream of data
  # and recursively turn it into a list of Elixir data types.
  #
  # It further defines a function for encoding Elixir data types into a binary
  # stream, using the Bolt.Sips.Internals.PackStream.Encoder protocol.

  @type value :: <<_::8, _::_*8>>

  @doc """
  Encodes a list of items into their binary representation.

  As developers tend to be lazy, single objects may be passed.

  ## Examples

      iex> Bolt.Sips.Internals.PackStream.encode "hello world"
      <<0x8B, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x77, 0x6F, 0x72, 0x6C, 0x64>>
  """
  @spec encode(any(), integer()) :: Bolt.Sips.Internals.PackStream.value() | <<_::16, _::_*8>>
  def encode(item, bolt_version) do
    Bolt.Sips.Internals.PackStream.Encoder.encode(item, bolt_version)
  end

  @doc """
  Decode data from Bolt binary format to Elixir type

  ## Example

      iex> Bolt.Sips.Internals.PackStream.decode(<<0xC3>>)
      [true]
  """
  @spec decode(binary(), integer()) :: list()
  def decode(data, bolt_version) do
    Bolt.Sips.Internals.PackStream.Decoder.decode(data, bolt_version)
  end
end
