defmodule Bolt.Sips.Internals.PackStream.Message.EncoderTest do
  use ExUnit.Case, async: true

  doctest Bolt.Sips.Internals.PackStream.Message.Encoder

  alias Bolt.Sips.Internals.PackStream.Message.Encoder
  alias Bolt.Sips.Internals.PackStream.BoltVersionHelper

  defmodule TestUser do
    defstruct name: "", bolt_sips: true
  end

  describe "Encode common messages" do
    Enum.each(BoltVersionHelper.available_versions(), fn bolt_version ->
      test "ACK_FAILURE (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x2, 0xB0, 0xE, 0x0, 0x0>> ==
                 Encoder.encode({:ack_failure, []}, unquote(bolt_version))
      end

      test "DISCARD_ALL (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x2, 0xB0, 0x2F, 0x0, 0x0>> ==
                 Encoder.encode({:discard_all, []}, unquote(bolt_version))
      end

      test "INIT without auth (bolt_version: #{bolt_version})" do
        assert <<0x0, _, 0xB2, 0x1, _::binary>> =
                 Encoder.encode({:init, []}, unquote(bolt_version))
      end

      test "INIT wit auth (bolt_version: #{bolt_version})" do
        assert <<0x0, _, 0xB2, 0x1, _::binary>> =
                 Encoder.encode({:init, [{"neo4j", "test"}]}, unquote(bolt_version))
      end

      test "PULL_ALL (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x2, 0xB0, 0x3F, 0x0, 0x0>> ==
                 Encoder.encode({:pull_all, []}, unquote(bolt_version))
      end

      test "RESET (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x2, 0xB0, 0xF, 0x0, 0x0>> ==
                 Encoder.encode({:reset, []}, unquote(bolt_version))
      end

      test "RUN without params (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x13, 0xB2, 0x10, 0x8F, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20, 0x31,
                 0x20, 0x41, 0x53, 0x20, 0x6E, 0x75, 0x6D, 0xA0, 0x0,
                 0x0>> == Encoder.encode({:run, ["RETURN 1 AS num"]}, unquote(bolt_version))
      end

      test "RUN with params (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x1D, 0xB2, 0x10, 0xD0, 0x13, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20,
                 0x7B, 0x6E, 0x75, 0x6D, 0x7D, 0x20, 0x41, 0x53, 0x20, 0x6E, 0x75, 0x6D, 0xA1,
                 0x83, 0x6E, 0x75, 0x6D, 0x5, 0x0,
                 0x0>> ==
                 Encoder.encode({:run, ["RETURN {num} AS num", %{num: 5}]}, unquote(bolt_version))
      end

      test "Bug fix: encoding strcut fails (bolt_version: #{bolt_version})" do
        query = "CREATE (n:User {props})"
        params = %{props: %TestUser{bolt_sips: true, name: "Strut"}}

        assert <<0x0, 0x39, 0xB2, 0x10, 0xD0, 0x17, 0x43, 0x52, 0x45, 0x41, 0x54, 0x45, 0x20,
                 0x28, 0x6E, 0x3A, 0x55, 0x73, 0x65, 0x72, 0x20, 0x7B, 0x70, 0x72, 0x6F, 0x70,
                 0x73, 0x7D, 0x29, 0xA1, 0x85, 0x70, 0x72, 0x6F, 0x70, 0x73, 0xA2, 0x89, 0x62,
                 0x6F, 0x6C, 0x74, 0x5F, 0x73, 0x69, 0x70, 0x73, 0xC3, 0x84,
                 _::binary>> = Encoder.encode({:run, [query, params]}, unquote(bolt_version))
      end
    end)
  end
end
