defmodule Bolt.Sips.Internals.PackStream.DecoderTest do
  use ExUnit.Case, async: true

  alias Bolt.Sips.Internals.PackStream.Decoder
  alias Bolt.Sips.Internals.PackStreamError
  alias Bolt.Sips.Internals.PackStream.BoltVersionHelper
  alias Bolt.Sips.Types

  test "Decode to common types" do
    Enum.each(BoltVersionHelper.available_versions(), fn bolt_version ->
      # Null
      assert [nil] == Decoder.decode(<<0xC0>>, bolt_version)

      # Boolean
      assert [false] == Decoder.decode(<<0xC2>>, bolt_version)
      assert [true] == Decoder.decode(<<0xC3>>, bolt_version)

      # Float
      assert [7.7] ==
               Decoder.decode(
                 <<0xC1, 0x40, 0x1E, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCD>>,
                 bolt_version
               )

      # String
      assert ["hello"] == Decoder.decode(<<0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F>>, bolt_version)

      # List
      assert [[]] == Decoder.decode(<<0x90>>, bolt_version)
      assert [[2, 4]] == Decoder.decode(<<0x92, 0x2, 0x4>>, bolt_version)

      # Integer
      assert [42] == Decoder.decode(<<0x2A>>, bolt_version)

      # Struct + Map
      # Unrealistic test: signature 0x01 (Success) is captured by mesage decoding
      # All structures are known, then this kind of return is not possible
      # assert(
      #   [[sig: 1, fields: [%{"id" => 1, "value" => "hello"}]]] ==
      #     Decoder.decode(
      #       <<0xB3, 0x1, 0xA2, 0x82, 0x69, 0x64, 0x1, 0x85, 0x76, 0x61, 0x6C, 0x75, 0x65, 0x85,
      #         0x68, 0x65, 0x6C, 0x6C, 0x6F>>,
      #       bolt_version
      #     )
      # )
    end)
  end

  test "Decodes Bolt V2 specific types" do
    assert [~D[2013-12-15]] == Decoder.decode(<<0xB1, 0x44, 0xC9, 0x3E, 0xB6>>, 2)

    assert [~T[09:34:23.724000]] ==
             Decoder.decode(<<0xB1, 0x74, 0xCB, 0x0, 0x0, 0x1F, 0x58, 0x36, 0x6, 0xD3, 0x0>>, 2)

    assert [~N[2018-04-05 12:34:00.543]] ==
             Decoder.decode(
               <<0xB2, 0x64, 0xCA, 0x5A, 0xC6, 0x17, 0xB8, 0xCA, 0x20, 0x5D, 0x85, 0xC0>>,
               2
             )

    ttz = Types.TimeWithTZOffset.create(~T[12:45:30.250000], 3600)

    assert [ttz] ==
             Decoder.decode(
               <<0xB2, 0x54, 0xCB, 0x0, 0x0, 0x29, 0xC5, 0xF8, 0x3C, 0x56, 0x80, 0xC9, 0xE,
                 0x10>>,
               2
             )

    dt = Bolt.Sips.TypesHelper.datetime_with_micro(~N[2016-05-24 13:26:08.543], "Europe/Berlin")

    assert [dt] ==
             Decoder.decode(
               <<0xB3, 0x66, 0xCA, 0x57, 0x44, 0x56, 0x70, 0xCA, 0x20, 0x5D, 0x85, 0xC0, 0x8D,
                 0x45, 0x75, 0x72, 0x6F, 0x70, 0x65, 0x2F, 0x42, 0x65, 0x72, 0x6C, 0x69, 0x6E>>,
               2
             )

    assert [
             %Types.DateTimeWithTZOffset{
               naive_datetime: ~N[2016-05-24 13:26:08.543],
               timezone_offset: 7200
             }
           ] =
             Decoder.decode(
               <<0xB3, 0x46, 0xCA, 0x57, 0x44, 0x56, 0x70, 0xCA, 0x20, 0x5D, 0x85, 0xC0, 0xC9,
                 0x1C, 0x20>>,
               2
             )

    assert [
             %Types.Duration{
               years: 1,
               months: 3,
               days: 34,
               hours: 2,
               minutes: 32,
               seconds: 54,
               nanoseconds: 5550
             }
           ] == Decoder.decode(<<0xB4, 0x45, 0xF, 0x22, 0xC9, 0x23, 0xD6, 0xC9, 0x15, 0xAE>>, 2)

    assert [
             %Types.Point{
               crs: "cartesian",
               height: nil,
               latitude: nil,
               longitude: nil,
               srid: 7203,
               x: 40.0,
               y: 45.0,
               z: nil
             }
           ] =
             Decoder.decode(
               <<0xB3, 0x58, 0xC9, 0x1C, 0x23, 0xC1, 0x40, 0x44, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                 0xC1, 0x40, 0x46, 0x80, 0x0, 0x0, 0x0, 0x0, 0x0>>,
               2
             )

    assert [
             %Types.Point{
               crs: "wgs-84",
               height: nil,
               latitude: 45.0,
               longitude: 40.0,
               srid: 4326,
               x: 40.0,
               y: 45.0,
               z: nil
             }
           ] =
             Decoder.decode(
               <<0xB3, 0x58, 0xC9, 0x10, 0xE6, 0xC1, 0x40, 0x44, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                 0xC1, 0x40, 0x46, 0x80, 0x0, 0x0, 0x0, 0x0, 0x0>>,
               2
             )

    assert [
             %Types.Point{
               crs: "cartesian-3d",
               height: nil,
               latitude: nil,
               longitude: nil,
               srid: 9157,
               x: 40.0,
               y: 45.0,
               z: 150.0
             }
           ] =
             Decoder.decode(
               <<0xB4, 0x59, 0xC9, 0x23, 0xC5, 0xC1, 0x40, 0x44, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                 0xC1, 0x40, 0x46, 0x80, 0x0, 0x0, 0x0, 0x0, 0x0, 0xC1, 0x40, 0x62, 0xC0, 0x0,
                 0x0, 0x0, 0x0, 0x0>>,
               2
             )

    assert [
             %Types.Point{
               crs: "wgs-84-3d",
               height: 150.0,
               latitude: 45.0,
               longitude: 40.0,
               srid: 4979,
               x: 40.0,
               y: 45.0,
               z: 150.0
             }
           ] =
             Decoder.decode(
               <<0xB4, 0x59, 0xC9, 0x13, 0x73, 0xC1, 0x40, 0x44, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                 0xC1, 0x40, 0x46, 0x80, 0x0, 0x0, 0x0, 0x0, 0x0, 0xC1, 0x40, 0x62, 0xC0, 0x0,
                 0x0, 0x0, 0x0, 0x0>>,
               2
             )
  end

  test "Fails to decode something unknown" do
    assert_raise PackStreamError, fn ->
      Decoder.decode(0xFF, 1)
    end
  end
end
