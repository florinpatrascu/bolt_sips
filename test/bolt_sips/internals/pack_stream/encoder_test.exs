defmodule Bolt.Sips.Internals.PackStream.EncoderTest do
  use ExUnit.Case, async: true

  alias Bolt.Sips.Internals.PackStream.Encoder
  alias Bolt.Sips.Internals.PackStream.BoltVersionHelper

  defmodule TestStruct do
    defstruct foo: "bar"
  end

  test "Encode common types" do
    Enum.each(BoltVersionHelper.available_versions(), fn bolt_version ->
      # Atom
      assert <<0xC0>> = Encoder.encode(nil, bolt_version)
      assert <<_::binary>> = Encoder.encode(true, bolt_version)
      assert <<_::binary>> = Encoder.encode(:hello, bolt_version)

      # String
      assert <<_::binary>> = Encoder.encode("hello", bolt_version)

      # Integer
      assert <<_::binary>> = Encoder.encode(7, bolt_version)

      # Float
      assert <<_::binary>> = Encoder.encode(7.7, bolt_version)

      # List
      assert <<_::binary>> = Encoder.encode([], bolt_version)
      assert <<_::binary>> = Encoder.encode([2, 4], bolt_version)

      # Map
      assert <<_::binary>> = Encoder.encode(%{ok: 5}, bolt_version)

      # Struct
      assert <<_::binary>> = Encoder.encode({0x01, ["i", "am", "params"]}, bolt_version)
    end)
  end

  test "unkown type" do
    assert_raise Bolt.Sips.Internals.PackStreamError, fn ->
      Encoder.encode({:error, "unencodable"}, 1)
    end
  end
end
