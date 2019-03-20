defmodule Bolt.Sips.Internals.PackStream.MessageTest do
  use ExUnit.Case, async: true

  alias Bolt.Sips.Internals.PackStream.Message
  alias Bolt.Sips.Internals.PackStream.BoltVersionHelper

  describe "Encode all-bolt-version-compliant message:" do
    Enum.each(BoltVersionHelper.available_versions(), fn bolt_version ->
      test "ACK_FAILURE (bolt_version: #{bolt_version})" do
        assert <<_, _, _, 0x0E, _::binary>> =
                 Message.encode({:ack_failure, []}, unquote(bolt_version))
      end

      test "DISCARD_ALL (bolt_version: #{bolt_version})" do
        assert <<_, _, _, 0x2F, _::binary>> =
                 Message.encode({:discard_all, []}, unquote(bolt_version))
      end

      test "INIT without auth (bolt_version: #{bolt_version})" do
        assert <<_, _, _, 0x01, _::binary>> = Message.encode({:init, []}, unquote(bolt_version))
      end

      test "INIT with auth (bolt_version: #{bolt_version})" do
        assert <<_, _, _, 0x01, _::binary>> =
                 Message.encode({:init, [{"neo4j", "password"}]}, unquote(bolt_version))
      end

      test "PULL_ALL (bolt_version: #{bolt_version})" do
        assert <<_, _, _, 0x3F, _::binary>> =
                 Message.encode({:pull_all, []}, unquote(bolt_version))
      end

      test "RESET (bolt_version: #{bolt_version})" do
        assert <<_, _, _, 0x0F, _::binary>> = Message.encode({:reset, []}, unquote(bolt_version))
      end

      test "RUN without params (bolt_version: #{bolt_version})" do
        assert <<_, _, _, 0x10, _::binary>> =
                 Message.encode({:run, ["RETURN 1 AS num"]}, unquote(bolt_version))
      end

      test "RUN with params (bolt_version: #{bolt_version})" do
        assert <<_, _, _, 0x10, _::binary>> =
                 Message.encode({:run, ["RETURN {num} AS num", %{num: 5}]}, unquote(bolt_version))
      end
    end)
  end

  describe "Decode all-bolt-version-compliant message:" do
    Enum.each(BoltVersionHelper.available_versions(), fn bolt_version ->
      test "SUCESS (bolt_version: #{bolt_version})" do
        success_hex =
          <<0xB1, 0x70, 0xA1, 0x86, 0x73, 0x65, 0x72, 0x76, 0x65, 0x72, 0x8B, 0x4E, 0x65, 0x6F,
            0x34, 0x6A, 0x2F, 0x33, 0x2E, 0x34, 0x2E, 0x31>>

        assert {:success, _} = Message.decode(success_hex, unquote(bolt_version))
      end

      test "FAILURE (bolt_version: #{bolt_version})" do
        failure_hex =
          <<0xB1, 0x7F, 0xA2, 0x84, 0x63, 0x6F, 0x64, 0x65, 0xD0, 0x25, 0x4E, 0x65, 0x6F, 0x2E,
            0x43, 0x6C, 0x69, 0x65, 0x6E, 0x74, 0x45, 0x72, 0x72, 0x6F, 0x72, 0x2E, 0x53, 0x65,
            0x63, 0x75, 0x72, 0x69, 0x74, 0x79, 0x2E, 0x55, 0x6E, 0x61, 0x75, 0x74, 0x68, 0x6F,
            0x72, 0x69, 0x7A, 0x65, 0x64, 0x87, 0x6D, 0x65, 0x73, 0x73, 0x61, 0x67, 0x65, 0xD0,
            0x39, 0x54, 0x68, 0x65, 0x20, 0x63, 0x6C, 0x69, 0x65, 0x6E, 0x74, 0x20, 0x69, 0x73,
            0x20, 0x75, 0x6E, 0x61, 0x75, 0x74, 0x68, 0x6F, 0x72, 0x69, 0x7A, 0x65, 0x64, 0x20,
            0x64, 0x75, 0x65, 0x20, 0x74, 0x6F, 0x20, 0x61, 0x75, 0x74, 0x68, 0x65, 0x6E, 0x74,
            0x69, 0x63, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x20, 0x66, 0x61, 0x69, 0x6C, 0x75, 0x72,
            0x65, 0x2E>>

        assert {:failure, _} = Message.decode(failure_hex, unquote(bolt_version))
      end

      test "RECORD (bolt_version: #{bolt_version})" do
        assert {:record, _} = Message.decode(<<0xB1, 0x71, 0x91, 0x1>>, unquote(bolt_version))
      end

      test "IGNORED (bolt_version: #{bolt_version})" do
        assert {:ignored, _} = Message.decode(<<0xB0, 0x7E>>, unquote(bolt_version))
      end
    end)
  end
end
