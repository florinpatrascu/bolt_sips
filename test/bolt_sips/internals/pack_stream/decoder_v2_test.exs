defmodule Bolt.Sips.Internals.PackStream.DecoderV2Test do
  use ExUnit.Case, async: true
  alias Bolt.Sips.Internals.PackStream.DecoderV2
  alias Bolt.Sips.Types.{TimeWithTZOffset, DateTimeWithTZOffset, Duration, Point}

  describe "Decode temporal data:" do
    test "date post 1970-01-01" do
      assert [~D[2018-07-29]] == DecoderV2.decode({0x44, <<0xC9, 0x45, 0x4D>>, 1}, 2)
    end

    test "date pre 1970-01-01" do
      assert [~D[1918-07-29]] == DecoderV2.decode({0x44, <<0xC9, 0xB6, 0xA0>>, 1}, 2)
    end

    test "local time" do
      assert [~T[13:25:01.952456]] ==
               DecoderV2.decode(
                 {0x74, <<0xCB, 0x0, 0x0, 0x2B, 0xEE, 0x2C, 0xB7, 0xD5, 0x40>>, 1},
                 2
               )
    end

    test "local datetime" do
      assert [~N[2014-11-30 16:15:01.435]] ==
               DecoderV2.decode(
                 {0x64, <<0xCA, 0x54, 0x7B, 0x42, 0x85, 0xCA, 0x19, 0xED, 0x92, 0xC0>>, 2},
                 2
               )
    end

    test "Time with timezone offzet" do
      assert [%TimeWithTZOffset{time: ~T[04:45:32.123000], timezone_offset: 7200}] ==
               DecoderV2.decode(
                 {0x54, <<0xCB, 0x0, 0x0, 0xF, 0x94, 0xE2, 0x1B, 0xC, 0xC0, 0xC9, 0x1C, 0x20>>,
                  2},
                 2
               )
    end

    test "Datetime ith zone id" do
      dt = Bolt.Sips.TypesHelper.datetime_with_micro(~N[1998-03-18 06:25:12.123], "Europe/Paris")

      assert [dt] ==
               DecoderV2.decode(
                 {0x66,
                  <<0xCA, 0x35, 0xF, 0x68, 0xC8, 0xCA, 0x7, 0x54, 0xD4, 0xC0, 0x8C, 0x45, 0x75,
                    0x72, 0x6F, 0x70, 0x65, 0x2F, 0x50, 0x61, 0x72, 0x69, 0x73>>, 3},
                 2
               )
    end

    test "Datetime with zone id" do
      assert [
               %DateTimeWithTZOffset{
                 naive_datetime: ~N[1998-03-18 06:25:12.123],
                 timezone_offset: 7200
               }
             ] ==
               DecoderV2.decode(
                 {0x46,
                  <<0xCA, 0x35, 0xF, 0x68, 0xC8, 0xCA, 0x7, 0x54, 0xD4, 0xC0, 0xC9, 0x1C, 0x20>>,
                  3},
                 2
               )
    end

    test "Duration" do
      assert [
               %Duration{
                 days: 11,
                 hours: 15,
                 minutes: 0,
                 months: 8,
                 nanoseconds: 5550,
                 seconds: 21,
                 weeks: 0,
                 years: 3
               }
             ] ==
               DecoderV2.decode(
                 {0x45, <<0x2C, 0xB, 0xCA, 0x0, 0x0, 0xD3, 0x5, 0xC9, 0x15, 0xAE>>, 4},
                 2
               )
    end

    test "Point2D (cartesian)" do
      assert [
               %Point{
                 crs: "cartesian",
                 height: nil,
                 latitude: nil,
                 longitude: nil,
                 srid: 7203,
                 x: 45.0003,
                 y: 34.5434,
                 z: nil
               }
             ] ==
               DecoderV2.decode(
                 {0x58,
                  <<0xC9, 0x1C, 0x23, 0xC1, 0x40, 0x46, 0x80, 0x9, 0xD4, 0x95, 0x18, 0x2B, 0xC1,
                    0x40, 0x41, 0x45, 0x8E, 0x21, 0x96, 0x52, 0xBD>>, 3},
                 2
               )
    end

    test "Point2D (geographic)" do
      assert [
               %Point{
                 crs: "wgs-84",
                 height: nil,
                 latitude: 15.00943,
                 longitude: 20.45352,
                 srid: 4326,
                 x: 20.45352,
                 y: 15.00943,
                 z: nil
               }
             ] ==
               DecoderV2.decode(
                 {0x58,
                  <<0xC9, 0x10, 0xE6, 0xC1, 0x40, 0x34, 0x74, 0x19, 0xE3, 0x0, 0x14, 0xF9, 0xC1,
                    0x40, 0x2E, 0x4, 0xD4, 0x2, 0x4B, 0x33, 0xDB>>, 3},
                 2
               )
    end

    test "Point3D (cartesian)" do
      assert [
               %Point{
                 crs: "cartesian-3d",
                 height: nil,
                 latitude: nil,
                 longitude: nil,
                 srid: 9157,
                 x: 48.8354,
                 y: 12.72468,
                 z: 50.004
               }
             ] ==
               DecoderV2.decode(
                 {0x59,
                  <<0xC9, 0x23, 0xC5, 0xC1, 0x40, 0x48, 0x6A, 0xEE, 0x63, 0x1F, 0x8A, 0x9, 0xC1,
                    0x40, 0x29, 0x73, 0x9, 0x41, 0xC8, 0x21, 0x6C, 0xC1, 0x40, 0x49, 0x0, 0x83,
                    0x12, 0x6E, 0x97, 0x8D>>, 4},
                 2
               )
    end

    test "Point3D (geographic)" do
      assert [
               %Point{
                 crs: "wgs-84-3d",
                 height: -123.0004,
                 latitude: 70.40958,
                 longitude: 13.39538,
                 srid: 4979,
                 x: 13.39538,
                 y: 70.40958,
                 z: -123.0004
               }
             ] ==
               DecoderV2.decode(
                 {0x59,
                  <<0xC9, 0x13, 0x73, 0xC1, 0x40, 0x2A, 0xCA, 0x6F, 0x3F, 0x52, 0xFC, 0x26, 0xC1,
                    0x40, 0x51, 0x9A, 0x36, 0x8F, 0x8, 0x46, 0x20, 0xC1, 0xC0, 0x5E, 0xC0, 0x6,
                    0x8D, 0xB8, 0xBA, 0xC7>>, 4},
                 2
               )
    end
  end
end
