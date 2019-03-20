defmodule Bolt.Sips.Internals.PackStream.EncoderV1Test do
  use ExUnit.Case, async: true

  alias Bolt.Sips.Internals.PackStream.EncoderV1

  defmodule TestStruct do
    defstruct foo: "bar"
  end

  doctest Bolt.Sips.Internals.PackStream.EncoderV1

  test "encodes null" do
    assert EncoderV1.encode_atom(nil, 1) == <<0xC0>>
  end

  test "encodes boolean" do
    assert EncoderV1.encode_atom(true, 1) == <<0xC3>>
    assert EncoderV1.encode_atom(false, 1) == <<0xC2>>
  end

  test "encodes atom" do
    assert EncoderV1.encode_atom(:hello, 1) == <<0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F>>
  end

  test "encodes string" do
    assert EncoderV1.encode_string("", 1) == <<0x80>>
    assert EncoderV1.encode_string("Short", 1) == <<0x85, 0x53, 0x68, 0x6F, 0x72, 0x74>>

    # 30 bytes due to umlauts
    long_8 = "This is a räther löng string"
    assert <<0xD0, 0x1E, _::binary-size(30)>> = EncoderV1.encode_string(long_8, 1)

    long_16 = """
    For encoded string containing fewer than 16 bytes, including empty strings,
    the marker byte should contain the high-order nibble `1000` followed by a
    low-order nibble containing the size. The encoded data then immediately
    follows the marker.

    For encoded string containing 16 bytes or more, the marker 0xD0, 0xD1 or
    0xD2 should be used, depending on scale. This marker is followed by the
    size and the UTF-8 encoded data.
    """

    assert <<0xD1, 0x01, 0xA5, _::binary-size(421)>> = EncoderV1.encode_string(long_16, 1)

    long_32 = String.duplicate("a", 66_000)
    assert <<0xD2, 66_000::32, _::binary-size(66_000)>> = EncoderV1.encode_string(long_32, 1)
  end

  test "encodes integer" do
    assert EncoderV1.encode_integer(0, 1) == <<0x00>>
    assert EncoderV1.encode_integer(42, 1) == <<0x2A>>
    assert EncoderV1.encode_integer(-42, 1) == <<0xC8, 0xD6>>
    assert EncoderV1.encode_integer(420, 1) == <<0xC9, 0x01, 0xA4>>
    assert EncoderV1.encode_integer(33_000, 1) == <<0xCA, 0x00, 0x00, 0x80, 0xE8>>

    assert EncoderV1.encode_integer(2_150_000_000, 1) ==
             <<0xCB, 0x00, 0x00, 0x00, 0x00, 0x80, 0x26, 0x65, 0x80>>
  end

  test "encodes float" do
    assert EncoderV1.encode_float(+1.1, 1) ==
             <<0xC1, 0x3F, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A>>

    assert EncoderV1.encode_float(-1.1, 1) ==
             <<0xC1, 0xBF, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A>>
  end

  test "encodes list" do
    assert EncoderV1.encode_list([], 1) == <<0x90>>

    list_8 = Stream.repeatedly(fn -> "a" end) |> Enum.take(16)
    assert <<0xD4, 16::8, _::binary-size(32)>> = EncoderV1.encode_list(list_8, 1)

    list_16 = Stream.repeatedly(fn -> "a" end) |> Enum.take(256)
    assert <<0xD5, 256::16, _::binary-size(512)>> = EncoderV1.encode_list(list_16, 1)

    list_32 = Stream.repeatedly(fn -> "a" end) |> Enum.take(66_000)
    assert <<0xD6, 66_000::32, _::binary-size(132_000)>> = EncoderV1.encode_list(list_32, 1)
  end

  test "encodes map" do
    assert EncoderV1.encode_map(%{}, 1) == <<0xA0>>

    map_8 = 1..16 |> Enum.map(&{&1, "a"}) |> Map.new()
    assert <<0xD8, 16::8>> <> _rest = EncoderV1.encode_map(map_8, 1)

    map_16 = 1..256 |> Enum.map(&{&1, "a"}) |> Map.new()
    assert <<0xD9, 256::16>> <> _rest = EncoderV1.encode_map(map_16, 1)

    map_32 = 1..66_000 |> Enum.map(&{&1, "a"}) |> Map.new()
    assert <<0xDA, 66_000::32>> <> _rest = EncoderV1.encode_map(map_32, 1)
  end

  test "encodes a struct" do
    assert <<0xB2, 0x1, 0x85, 0x66, 0x69, 0x72, 0x73, 0x74, 0x86, 0x73, 0x65, 0x63, 0x6F, 0x6E,
             0x64>> == EncoderV1.encode_struct({0x01, ["first", "second"]}, 1)

    assert <<0xDC, 0x6F, _::binary>> = EncoderV1.encode_struct({0x01, Enum.into(1..111, [])}, 1)

    assert <<0xDD, 0x1, 0x4D, _::binary>> =
             EncoderV1.encode_struct({0x01, Enum.into(1..333, [])}, 1)

    # Test for a fixed bug
    assert <<0xB1, 0x1, 0xA1, 0x83, 0x66, 0x6F, 0x6F, 0x83, 0x62, 0x61, 0x72>> ==
             EncoderV1.encode_struct({0x01, [%TestStruct{}]}, 1)
  end
end
