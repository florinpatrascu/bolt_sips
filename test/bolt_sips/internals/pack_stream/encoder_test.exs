defmodule Bolt.Sips.Internals.PackStream.EncoderTest do
  use ExUnit.Case, async: false

  alias Bolt.Sips.Internals.PackStream.Encoder
  alias Bolt.Sips.Internals.PackStream.BoltVersionHelper
  alias Bolt.Sips.Types
  alias Bolt.Sips.TypesHelper

  defmodule TestStruct do
    defstruct foo: "bar"
  end

  test "Encode common types" do
    Enum.each(BoltVersionHelper.available_versions(), fn bolt_version ->
      # Atom
      assert <<0xC0>> == Encoder.encode(nil, bolt_version)
      assert <<0xC3>> == Encoder.encode(true, bolt_version)
      assert <<0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F>> == Encoder.encode(:hello, bolt_version)

      # String
      assert <<0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F>> == Encoder.encode("hello", bolt_version)

      # Integer
      assert <<0x7>> == Encoder.encode(7, bolt_version)

      # Float
      assert <<0xC1, 0x40, 0x1E, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCD>> ==
               Encoder.encode(7.7, bolt_version)

      # List
      assert <<0x90>> == Encoder.encode([], bolt_version)
      assert <<0x92, 0x2, 0x4>> == Encoder.encode([2, 4], bolt_version)

      # Map
      assert <<0xA1, 0x82, 0x6F, 0x6B, 0x5>> == Encoder.encode(%{ok: 5}, bolt_version)

      # Struct
      assert <<0xB3, 0x1, 0x81, 0x69, 0x82, 0x61, 0x6D, 0x86, 0x70, 0x61, 0x72, 0x61, 0x6D, 0x73>> ==
               Encoder.encode({0x01, ["i", "am", "params"]}, bolt_version)
    end)
  end

  test "Encode bolt >= 2 types" do
    BoltVersionHelper.available_versions()
    |> Enum.filter(&(&1 >= 2))
    |> Enum.each(fn bolt_version ->
      # Local Time
      assert <<0xB1, 0x74, _::binary>> = Encoder.encode(~T[14:45:53.34], bolt_version)

      # Time with TZ Offset
      assert <<0xB2, 0x54, _::binary>> =
               Encoder.encode(
                 Types.TimeWithTZOffset.create(~T[12:45:30.250000], 3600),
                 bolt_version
               )

      # Date
      assert <<0xB1, 0x44, _::binary>> = Encoder.encode(~D[2013-05-06], bolt_version)

      # Local date time: NaiveDateTime
      assert <<0xB2, 0x64, _::binary>> = Encoder.encode(~N[2018-04-05 12:34:00.543], bolt_version)

      # Datetime with timezone offset
      assert <<0xB3, 0x46, _::binary>> =
               Encoder.encode(
                 Types.DateTimeWithTZOffset.create(~N[2016-05-24 13:26:08.543], 7200),
                 bolt_version
               )

      # Datetime with timezone id
      assert <<0xB3, 0x66, _::binary>> =
               Encoder.encode(
                 TypesHelper.datetime_with_micro(~N[2016-05-24 13:26:08.543], "Europe/Berlin"),
                 bolt_version
               )

      duration = %Types.Duration{
        years: 2,
        months: 3,
        weeks: 2,
        days: 23,
        hours: 8,
        minutes: 2,
        seconds: 4,
        nanoseconds: 3234
      }

      # Duration
      assert <<0xB4, 0x45, _::binary>> = Encoder.encode(duration, bolt_version)

      # Point 2D
      assert <<0xB3, 0x58, _::binary>> =
               Encoder.encode(Types.Point.create(:cartesian, 40, 45), bolt_version)

      assert <<0xB3, 0x58, _::binary>> =
               Encoder.encode(Types.Point.create(:wgs_84, 40, 45), bolt_version)

      # Point 3D
      assert <<0xB4, 0x59, _::binary>> =
               Encoder.encode(Types.Point.create(:cartesian, 40, 45, 150), bolt_version)

      assert <<0xB4, 0x59, _::binary>> =
               Encoder.encode(Types.Point.create(:wgs_84, 40, 45, 150), bolt_version)
    end)
  end

  test "unkown type" do
    assert_raise Bolt.Sips.Internals.PackStreamError, fn ->
      Encoder.encode({:error, "unencodable"}, 1)
    end
  end
end
