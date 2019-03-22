defmodule Bolt.Sips.Internals.PackStream.DecoderTest do
  use ExUnit.Case, async: true

  alias Bolt.Sips.Internals.PackStream.Decoder
  alias Bolt.Sips.Internals.PackStreamError
  alias Bolt.Sips.Internals.BoltVersionHelper
  alias Bolt.Sips.Types

  describe "Decode common types" do
    Enum.each(BoltVersionHelper.available_versions(), fn bolt_version ->
      test "Null (bolt_version: #{bolt_version})" do
        assert [nil] == Decoder.decode(<<0xC0>>, unquote(bolt_version))
      end

      test "Boolean (bolt_version: #{bolt_version})" do
        assert [false] == Decoder.decode(<<0xC2>>, unquote(bolt_version))
        assert [true] == Decoder.decode(<<0xC3>>, unquote(bolt_version))
      end

      test "Float (bolt_version: #{bolt_version})" do
        assert [7.7] ==
                 Decoder.decode(
                   <<0xC1, 0x40, 0x1E, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCD>>,
                   unquote(bolt_version)
                 )
      end

      test "String (bolt_version: #{bolt_version})" do
        assert ["hello"] ==
                 Decoder.decode(<<0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F>>, unquote(bolt_version))
      end

      test "List (bolt_version: #{bolt_version})" do
        assert [[]] == Decoder.decode(<<0x90>>, unquote(bolt_version))
        assert [[2, 4]] == Decoder.decode(<<0x92, 0x2, 0x4>>, unquote(bolt_version))
      end

      test "Integer (bolt_version: #{bolt_version})" do
        assert [42] == Decoder.decode(<<0x2A>>, unquote(bolt_version))
      end

      test "Node (bolt_version: #{bolt_version})" do
        node =
          <<0x91, 0xB3, 0x4E, 0x11, 0x91, 0x86, 0x50, 0x65, 0x72, 0x73, 0x6F, 0x6E, 0xA2, 0x84,
            0x6E, 0x61, 0x6D, 0x65, 0xD0, 0x10, 0x50, 0x61, 0x74, 0x72, 0x69, 0x63, 0x6B, 0x20,
            0x52, 0x6F, 0x74, 0x68, 0x66, 0x75, 0x73, 0x73, 0x89, 0x62, 0x6F, 0x6C, 0x74, 0x5F,
            0x73, 0x69, 0x70, 0x73, 0xC3>>

        assert [
                 [
                   %Bolt.Sips.Types.Node{
                     id: 17,
                     labels: ["Person"],
                     properties: %{"bolt_sips" => true, "name" => "Patrick Rothfuss"}
                   }
                 ]
               ] == Decoder.decode(node, unquote(bolt_version))
      end

      test "Relationship (bolt_version: #{bolt_version})" do
        rel = <<0x91, 0xB5, 0x52, 0x50, 0x46, 0x43, 0x85, 0x57, 0x52, 0x4F, 0x54, 0x45, 0xA0>>

        assert [
                 [
                   %Bolt.Sips.Types.Relationship{
                     end: 67,
                     id: 80,
                     properties: %{},
                     start: 70,
                     type: "WROTE"
                   }
                 ]
               ] = Decoder.decode(rel, unquote(bolt_version))
      end

      # test "UnboundRelationship (bolt_version: #{bolt_version})" do
      # end

      test "Path (bolt_version: #{bolt_version})" do
        path =
          <<0x91, 0xB3, 0x50, 0x92, 0xB3, 0x4E, 0x30, 0x90, 0xA2, 0x84, 0x6E, 0x61, 0x6D, 0x65,
            0x85, 0x41, 0x6C, 0x69, 0x63, 0x65, 0x89, 0x62, 0x6F, 0x6C, 0x74, 0x5F, 0x73, 0x69,
            0x70, 0x73, 0xC3, 0xB3, 0x4E, 0x38, 0x90, 0xA2, 0x84, 0x6E, 0x61, 0x6D, 0x65, 0x83,
            0x42, 0x6F, 0x62, 0x89, 0x62, 0x6F, 0x6C, 0x74, 0x5F, 0x73, 0x69, 0x70, 0x73, 0xC3,
            0x91, 0xB3, 0x72, 0x13, 0x85, 0x4B, 0x4E, 0x4F, 0x57, 0x53, 0xA0, 0x92, 0x1, 0x1>>

        [
          [
            %Bolt.Sips.Types.Path{
              nodes: [
                %Bolt.Sips.Types.Node{
                  id: 48,
                  labels: [],
                  properties: %{"bolt_sips" => true, "name" => "Alice"}
                },
                %Bolt.Sips.Types.Node{
                  id: 56,
                  labels: [],
                  properties: %{"bolt_sips" => true, "name" => "Bob"}
                }
              ],
              relationships: [
                %Bolt.Sips.Types.UnboundRelationship{
                  end: nil,
                  id: 19,
                  properties: %{},
                  start: nil,
                  type: "KNOWS"
                }
              ],
              sequence: [1, 1]
            }
          ]
        ] = Decoder.decode(path, unquote(bolt_version))
      end

      test "Fails to decode something unknown (bolt_version: #{bolt_version})" do
        assert_raise PackStreamError, fn ->
          Decoder.decode(0xFF, unquote(bolt_version))
        end
      end
    end)
  end

  describe "Decodes Bolt >= 2 specific types" do
    BoltVersionHelper.available_versions()
    |> Enum.filter(&(&1 >= 2))
    |> Enum.each(fn bolt_version ->
      test "Local Date (bolt_version: #{bolt_version})" do
        assert [~D[2013-12-15]] ==
                 Decoder.decode(<<0xB1, 0x44, 0xC9, 0x3E, 0xB6>>, unquote(bolt_version))
      end

      test "Local Time (bolt_version: #{bolt_version})" do
        assert [~T[09:34:23.724000]] ==
                 Decoder.decode(
                   <<0xB1, 0x74, 0xCB, 0x0, 0x0, 0x1F, 0x58, 0x36, 0x6, 0xD3, 0x0>>,
                   unquote(bolt_version)
                 )
      end

      test "Local DateTime (bolt_version: #{bolt_version})" do
        assert [~N[2018-04-05 12:34:00.543]] ==
                 Decoder.decode(
                   <<0xB2, 0x64, 0xCA, 0x5A, 0xC6, 0x17, 0xB8, 0xCA, 0x20, 0x5D, 0x85, 0xC0>>,
                   unquote(bolt_version)
                 )
      end

      test "Time with timezone offset (bolt_version: #{bolt_version})" do
        ttz = Types.TimeWithTZOffset.create(~T[12:45:30.250000], 3600)

        assert [ttz] ==
                 Decoder.decode(
                   <<0xB2, 0x54, 0xCB, 0x0, 0x0, 0x29, 0xC5, 0xF8, 0x3C, 0x56, 0x80, 0xC9, 0xE,
                     0x10>>,
                   unquote(bolt_version)
                 )
      end

      test "Datetime with timezone id (bolt_version: #{bolt_version})" do
        dt =
          Bolt.Sips.TypesHelper.datetime_with_micro(~N[2016-05-24 13:26:08.543], "Europe/Berlin")

        assert [dt] ==
                 Decoder.decode(
                   <<0xB3, 0x66, 0xCA, 0x57, 0x44, 0x56, 0x70, 0xCA, 0x20, 0x5D, 0x85, 0xC0, 0x8D,
                     0x45, 0x75, 0x72, 0x6F, 0x70, 0x65, 0x2F, 0x42, 0x65, 0x72, 0x6C, 0x69,
                     0x6E>>,
                   unquote(bolt_version)
                 )
      end

      test "Datetime with timezone offset (bolt_version: #{bolt_version})" do
        assert [
                 %Types.DateTimeWithTZOffset{
                   naive_datetime: ~N[2016-05-24 13:26:08.543],
                   timezone_offset: 7200
                 }
               ] =
                 Decoder.decode(
                   <<0xB3, 0x46, 0xCA, 0x57, 0x44, 0x56, 0x70, 0xCA, 0x20, 0x5D, 0x85, 0xC0, 0xC9,
                     0x1C, 0x20>>,
                   unquote(bolt_version)
                 )
      end

      test "Duration (bolt_version: #{bolt_version})" do
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
               ] ==
                 Decoder.decode(
                   <<0xB4, 0x45, 0xF, 0x22, 0xC9, 0x23, 0xD6, 0xC9, 0x15, 0xAE>>,
                   unquote(bolt_version)
                 )
      end

      test "Point 2D cartesian (bolt_version: #{bolt_version})" do
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
                   unquote(bolt_version)
                 )
      end

      test "Point 2D geographic (bolt_version: #{bolt_version})" do
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
                   unquote(bolt_version)
                 )
      end

      test "Point 3D cartesian (bolt_version: #{bolt_version})" do
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
                   unquote(bolt_version)
                 )
      end

      test "Point 3D geographic (bolt_version: #{bolt_version})" do
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
                   unquote(bolt_version)
                 )
      end
    end)
  end
end
