defmodule Bolt.Sips.Internals.PackStream.DecoderTest do
  use ExUnit.Case, async: true

  alias Bolt.Sips.Internals.PackStream.Decoder
  alias Bolt.Sips.Internals.PackStreamError
  alias Bolt.Sips.Internals.PackStream.BoltVersionHelper

  test "Decode to common types" do
    Enum.each(BoltVersionHelper.available_versions(), fn bolt_version ->
      # Null
      assert [nil] == Decoder.decode(<<0xC0>>, bolt_version)

      # Boolean
      assert [false] == Decoder.decode(<<0xC2>>, bolt_version)
      assert [true] == Decoder.decode(<<0xC3>>, bolt_version)

      # Float
      assert [7.7] =
               Decoder.decode(
                 <<0xC1, 0x40, 0x1E, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCD>>,
                 bolt_version
               )

      # String
      assert ["hello"] = Decoder.decode(<<0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F>>, bolt_version)

      # List
      assert [[]] = Decoder.decode(<<0x90>>, bolt_version)
      assert [[2, 4]] = Decoder.decode(<<0x92, 0x2, 0x4>>, bolt_version)

      # Integer
      assert [42] = Decoder.decode(<<0x2A>>, bolt_version)

      # Struct + Map
      assert(
        [[sig: 1, fields: [%{"id" => 1, "value" => "hello"}]]] =
          Decoder.decode(
            <<0xB3, 0x1, 0xA2, 0x82, 0x69, 0x64, 0x1, 0x85, 0x76, 0x61, 0x6C, 0x75, 0x65, 0x85,
              0x68, 0x65, 0x6C, 0x6C, 0x6F>>,
            bolt_version
          )
      )
    end)
  end

  test "Fails to decode something unknown" do
    assert_raise PackStreamError, fn ->
      Decoder.decode(0xFF, 1)
    end
  end
end
