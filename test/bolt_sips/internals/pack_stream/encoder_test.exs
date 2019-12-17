defmodule Bolt.Sips.Internals.PackStream.EncoderTest do
  use ExUnit.Case, async: false

  alias Bolt.Sips.Internals.PackStream.Encoder
  alias Bolt.Sips.Internals.BoltVersionHelper
  alias Bolt.Sips.Types
  alias Bolt.Sips.TypesHelper

  defmodule TestStruct do
    defstruct foo: "bar"
  end

  describe "Encode common types:" do
    Enum.each(BoltVersionHelper.available_versions(), fn bolt_version ->
      test "Null (bolt_version: #{bolt_version})" do
        assert <<0xC0>> == :erlang.iolist_to_binary(Encoder.encode(nil, unquote(bolt_version)))
      end

      test "Boolean (bolt_version: #{bolt_version})" do
        assert <<0xC3>> == :erlang.iolist_to_binary(Encoder.encode(true, unquote(bolt_version)))
        assert <<0xC2>> == :erlang.iolist_to_binary(Encoder.encode(false, unquote(bolt_version)))
      end

      test "Atom (bolt_version: #{bolt_version})" do
        assert <<0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F>> ==
                 :erlang.iolist_to_binary(Encoder.encode(:hello, unquote(bolt_version)))
      end

      test "String (bolt_version: #{bolt_version})" do
        assert <<0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F>> ==
                 :erlang.iolist_to_binary(Encoder.encode("hello", unquote(bolt_version)))
      end

      test "Integer (bolt_version: #{bolt_version})" do
        assert <<0x7>> == :erlang.iolist_to_binary(Encoder.encode(7, unquote(bolt_version)))
      end

      test "Float (bolt_version: #{bolt_version})" do
        assert <<0xC1, 0x40, 0x1E, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCD>> ==
                 :erlang.iolist_to_binary(Encoder.encode(7.7, unquote(bolt_version)))
      end

      test "List (bolt_version: #{bolt_version})" do
        assert <<0x90>> == :erlang.iolist_to_binary(Encoder.encode([], unquote(bolt_version)))
        assert <<0x92, 0x2, 0x4>> == :erlang.iolist_to_binary(Encoder.encode([2, 4], unquote(bolt_version)))
      end

      test "Map (bolt_version: #{bolt_version})" do
        assert <<0xA1, 0x82, 0x6F, 0x6B, 0x5>> == :erlang.iolist_to_binary(Encoder.encode(%{ok: 5}, unquote(bolt_version)))
      end

      test "Struct (bolt_version: #{bolt_version})" do
        assert <<0xB3, 0x1, 0x81, 0x69, 0x82, 0x61, 0x6D, 0x86, 0x70, 0x61, 0x72, 0x61, 0x6D,
                 0x73>> ==
                 :erlang.iolist_to_binary(Encoder.encode({0x01, ["i", "am", "params"]}, unquote(bolt_version)))
      end

      test "raises error when trying to encode with unknown signature (bolt_version: #{
             bolt_version
           })" do
        assert_raise Bolt.Sips.Internals.PackStreamError, ~r/^unable to encode/i, fn ->
          Encoder.encode({128, []}, unquote(bolt_version))
        end

        assert_raise Bolt.Sips.Internals.PackStreamError, ~r/^unable to encode/i, fn ->
          Encoder.encode({-1, []}, unquote(bolt_version))
        end

        assert_raise Bolt.Sips.Internals.PackStreamError, ~r/^unable to encode/i, fn ->
          Encoder.encode({"a", []}, unquote(bolt_version))
        end
      end

      test "unkown type (bolt_version: #{bolt_version})" do
        assert_raise Bolt.Sips.Internals.PackStreamError, fn ->
          Encoder.encode({:error, "unencodable"}, unquote(bolt_version))
        end
      end
    end)
  end

  describe "Encode types for bolt >= 2" do
    BoltVersionHelper.available_versions()
    |> Enum.filter(&(&1 >= 2))
    |> Enum.each(fn bolt_version ->
      test "Local time (bolt_version: #{bolt_version})" do
        assert <<0xB1, 0x74, _::binary>> = :erlang.iolist_to_binary(Encoder.encode(~T[14:45:53.34], unquote(bolt_version)))
      end

      test "Time with TZ Offset (bolt_version: #{bolt_version})" do
        assert <<0xB2, 0x54, _::binary>> =
                 :erlang.iolist_to_binary(Encoder.encode(
                   Types.TimeWithTZOffset.create(~T[12:45:30.250000], 3600),
                   unquote(bolt_version)
                 ))
      end

      test "Date (bolt_version: #{bolt_version})" do
        assert <<0xB1, 0x44, _::binary>> = :erlang.iolist_to_binary(Encoder.encode(~D[2013-05-06], unquote(bolt_version)))
      end

      test "Local date time: NaiveDateTime (bolt_version: #{bolt_version})" do
        assert <<0xB2, 0x64, _::binary>> =
                 :erlang.iolist_to_binary(Encoder.encode(~N[2018-04-05 12:34:00.543], unquote(bolt_version)))
      end

      test "Datetime with timezone offset (bolt_version: #{bolt_version})" do
        assert <<0xB3, 0x46, _::binary>> =
                 :erlang.iolist_to_binary(Encoder.encode(
                   Types.DateTimeWithTZOffset.create(~N[2016-05-24 13:26:08.543], 7200),
                   unquote(bolt_version)
                 ))
      end

      test "Datetime with timezone id (bolt_version: #{bolt_version})" do
        assert <<0xB3, 0x66, _::binary>> =
                 :erlang.iolist_to_binary(Encoder.encode(
                   TypesHelper.datetime_with_micro(~N[2016-05-24 13:26:08.543], "Europe/Berlin"),
                   unquote(bolt_version)
                 ))
      end

      test "Duration (bolt_version: #{bolt_version})" do
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

        assert <<0xB4, 0x45, _::binary>> = :erlang.iolist_to_binary(Encoder.encode(duration, unquote(bolt_version)))
      end

      test "Point 2D cartesian (bolt_version: #{bolt_version})" do
        assert <<0xB3, 0x58, _::binary>> =
                 :erlang.iolist_to_binary(Encoder.encode(Types.Point.create(:cartesian, 40, 45), unquote(bolt_version)))
      end

      test "Point 2D geographic (bolt_version: #{bolt_version})" do
        assert <<0xB3, 0x58, _::binary>> =
                 :erlang.iolist_to_binary(Encoder.encode(Types.Point.create(:wgs_84, 40, 45), unquote(bolt_version)))
      end

      test "Point 3D cartesian (bolt_version: #{bolt_version})" do
        assert <<0xB4, 0x59, _::binary>> =
                 :erlang.iolist_to_binary(Encoder.encode(
                   Types.Point.create(:cartesian, 40, 45, 150),
                   unquote(bolt_version)
                 ))
      end

      test "Point 3D geographic (bolt_version: #{bolt_version})" do
        assert <<0xB4, 0x59, _::binary>> =
                 :erlang.iolist_to_binary(Encoder.encode(Types.Point.create(:wgs_84, 40, 45, 150), unquote(bolt_version)))
      end
    end)
  end
end
