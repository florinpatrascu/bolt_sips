defmodule Bolt.Sips.Internals.PackStream.Message.EncoderTest do
  use ExUnit.Case, async: true

  doctest Bolt.Sips.Internals.PackStream.Message.Encoder

  alias Bolt.Sips.Internals.PackStream.Message.Encoder
  alias Bolt.Sips.Metadata
  alias Bolt.Sips.Internals.BoltVersionHelper

  defmodule TestUser do
    defstruct name: "", bolt_sips: true
  end

  describe "Encode common messages" do
    Enum.each(BoltVersionHelper.available_versions(), fn bolt_version ->
      test "DISCARD_ALL (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x2, 0xB0, 0x2F, 0x0, 0x0>> ==
                :erlang.iolist_to_binary(Encoder.encode({:discard_all, []}, unquote(bolt_version)))
      end

      test "PULL_ALL (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x2, 0xB0, 0x3F, 0x0, 0x0>> ==
                 :erlang.iolist_to_binary(Encoder.encode({:pull_all, []}, unquote(bolt_version)))
      end

      test "RESET (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x2, 0xB0, 0xF, 0x0, 0x0>> ==
                 :erlang.iolist_to_binary(Encoder.encode({:reset, []}, unquote(bolt_version)))
      end
    end)
  end

  @doc """
  INIT is not valid in bolt >= 3
  RUN has one more params (metadata) in bolt >=3
  """
  describe "Encode message available only in Bolt <= 2" do
    BoltVersionHelper.available_versions()
    |> Enum.filter(&(&1 <= 2))
    |> Enum.each(fn bolt_version ->
      test "INIT without auth (bolt_version: #{bolt_version})" do
        assert <<0x0, _, 0xB2, 0x1, _::binary>> =
                 :erlang.iolist_to_binary(Encoder.encode({:init, []}, unquote(bolt_version)))
      end

      test "INIT wit auth (bolt_version: #{bolt_version})" do
        assert <<0x0, _, 0xB2, 0x1, _::binary>> =
                 :erlang.iolist_to_binary(Encoder.encode({:init, [{"neo4j", "test"}]}, unquote(bolt_version)))
      end

      test "ACK_FAILURE (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x2, 0xB0, 0xE, 0x0, 0x0>> ==
                 :erlang.iolist_to_binary(Encoder.encode({:ack_failure, []}, unquote(bolt_version)))
      end

      test "RUN without params (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x13, 0xB2, 0x10, 0x8F, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20, 0x31,
                 0x20, 0x41, 0x53, 0x20, 0x6E, 0x75, 0x6D, 0xA0, 0x0,
                 0x0>> == :erlang.iolist_to_binary(Encoder.encode({:run, ["RETURN 1 AS num"]}, unquote(bolt_version)))
      end

      test "RUN with params (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x1D, 0xB2, 0x10, 0xD0, 0x13, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20,
                 0x7B, 0x6E, 0x75, 0x6D, 0x7D, 0x20, 0x41, 0x53, 0x20, 0x6E, 0x75, 0x6D, 0xA1,
                 0x83, 0x6E, 0x75, 0x6D, 0x5, 0x0,
                 0x0>> ==
                 :erlang.iolist_to_binary(Encoder.encode({:run, ["RETURN {num} AS num", %{num: 5}]}, unquote(bolt_version)))
      end

      test "Bug fix: encoding struct fails (bolt_version: #{bolt_version})" do
        query = "CREATE (n:User {props})"
        params = %{props: %TestUser{bolt_sips: true, name: "Strut"}}

        assert <<0x0, 0x39, 0xB2, 0x10, 0xD0, 0x17, 0x43, 0x52, 0x45, 0x41, 0x54, 0x45, 0x20,
                 0x28, 0x6E, 0x3A, 0x55, 0x73, 0x65, 0x72, 0x20, 0x7B, 0x70, 0x72, 0x6F, 0x70,
                 0x73, 0x7D, 0x29, 0xA1, 0x85, 0x70, 0x72, 0x6F, 0x70, 0x73, 0xA2, 0x89, 0x62,
                 0x6F, 0x6C, 0x74, 0x5F, 0x73, 0x69, 0x70, 0x73, 0xC3, 0x84,
                 _::binary>> = :erlang.iolist_to_binary(Encoder.encode({:run, [query, params]}, unquote(bolt_version)))
      end
    end)
  end

  describe "Encode message available in Bolt >= 3" do
    BoltVersionHelper.available_versions()
    |> Enum.filter(&(&1 >= 3))
    |> Enum.each(fn bolt_version ->
      nil

      test "HELLO without params (bolt_version: #{bolt_version})" do
        assert <<0x0, _, 0xB1, 0x1, _::binary>> =
                 :erlang.iolist_to_binary(Encoder.encode({:hello, []}, unquote(bolt_version)))
      end

      test "HELLO with params (bolt_version: #{bolt_version})" do
        assert <<0x0, _, 0xB1, 0x1, _::binary>> =
                 :erlang.iolist_to_binary(Encoder.encode({:hello, [{"neo4j", "test"}]}, unquote(bolt_version)))
      end

      test "Encode GOODBYE (bolt_version: #{bolt_version})" do
        assert assert <<0x0, 0x2, 0xB0, 0x02, 0x0, 0x0>> ==
                        :erlang.iolist_to_binary(Encoder.encode({:goodbye, []}, unquote(bolt_version)))
      end

      test "BEGIN without params (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x3, 0xB1, 0x11, 0xA0, 0x0, 0x0>> ==
                 :erlang.iolist_to_binary(Encoder.encode({:begin, []}, unquote(bolt_version)))
      end

      test "BEGIN with params (bolt_version: #{bolt_version})" do
        {:ok, metadata} = Metadata.new(%{tx_timeout: 15000})

        assert <<0x0, 0x11, 0xB1, 0x11, 0xA1, 0x8A, 0x74, 0x78, 0x5F, 0x74, 0x69, 0x6D, 0x65,
                 0x6F, 0x75, 0x74, 0xC9, 0x3A, 0x98, 0x0,
                 0x0>> == :erlang.iolist_to_binary(Encoder.encode({:begin, [metadata]}, unquote(bolt_version)))
      end

      test "Encode COMMIT (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x2, 0xB0, 0x12, 0x0, 0x0>> ==
                 :erlang.iolist_to_binary(Encoder.encode({:commit, []}, unquote(bolt_version)))
      end

      test "Encode ROLLBACK (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x2, 0xB0, 0x13, 0x0, 0x0>> ==
                 :erlang.iolist_to_binary(Encoder.encode({:rollback, []}, unquote(bolt_version)))
      end

      test "RUN without params nor metadata (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x16, 0xB3, 0x10, 0xD0, 0x10, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20,
                 0x31, 0x36, 0x20, 0x41, 0x53, 0x20, 0x6E, 0x75, 0x6D, 0xA0, 0xA0, 0x0,
                 0x0>> == :erlang.iolist_to_binary(Encoder.encode({:run, ["RETURN 16 AS num"]}, unquote(bolt_version)))
      end

      test "RUN without params but with metadata (bolt_version: #{bolt_version})" do
        {:ok, metadata} = Metadata.new(%{tx_timeout: 15000})

        assert <<0x0, 0x24, 0xB3, 0x10, 0xD0, 0x10, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20,
                 0x31, 0x36, 0x20, 0x41, 0x53, 0x20, 0x6E, 0x75, 0x6D, 0xA0, 0xA1, 0x8A, 0x74,
                 0x78, 0x5F, 0x74, 0x69, 0x6D, 0x65, 0x6F, 0x75, 0x74, 0xC9, 0x3A, 0x98, 0x0,
                 0x0>> ==
                 :erlang.iolist_to_binary(Encoder.encode(
                   {:run, ["RETURN 16 AS num", %{}, metadata]},
                   unquote(bolt_version)
                 ))
      end

      test "RUN with params but without metadata (bolt_version: #{bolt_version})" do
        assert <<0x0, 0x1E, 0xB3, 0x10, 0xD0, 0x13, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20,
                 0x7B, 0x6E, 0x75, 0x6D, 0x7D, 0x20, 0x41, 0x53, 0x20, 0x6E, 0x75, 0x6D, 0xA1,
                 0x83, 0x6E, 0x75, 0x6D, 0x10, 0xA0, 0x0,
                 0x0>> ==
                 :erlang.iolist_to_binary(Encoder.encode(
                   {:run, ["RETURN {num} AS num", %{num: 16}]},
                   unquote(bolt_version)
                 ))
      end

      test "RUN with params and  metadata (bolt_version: #{bolt_version})" do
        {:ok, metadata} = Metadata.new(%{tx_timeout: 15000})

        assert <<0x0, 0x2C, 0xB3, 0x10, 0xD0, 0x13, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20,
                 0x7B, 0x6E, 0x75, 0x6D, 0x7D, 0x20, 0x41, 0x53, 0x20, 0x6E, 0x75, 0x6D, 0xA1,
                 0x83, 0x6E, 0x75, 0x6D, 0x10, 0xA1, 0x8A, 0x74, 0x78, 0x5F, 0x74, 0x69, 0x6D,
                 0x65, 0x6F, 0x75, 0x74, 0xC9, 0x3A, 0x98, 0x0,
                 0x0>> ==
                 :erlang.iolist_to_binary(Encoder.encode(
                   {:run, ["RETURN {num} AS num", %{num: 16}, metadata]},
                   unquote(bolt_version)
                 ))
      end

      test "Bug fix: encoding struct fails (bolt_version: #{bolt_version})" do
        query = "CREATE (n:User {props})"
        params = %{props: %TestUser{bolt_sips: true, name: "Strut"}}

        assert <<0x0, 0x3A, 0xB3, 0x10, 0xD0, 0x17, 0x43, 0x52, 0x45, 0x41, 0x54, 0x45, 0x20,
                 0x28, 0x6E, 0x3A, 0x55, 0x73, 0x65, 0x72, 0x20, 0x7B, 0x70, 0x72, 0x6F, 0x70,
                 0x73, 0x7D, 0x29, 0xA1, 0x85, 0x70, 0x72, 0x6F, 0x70, 0x73, 0xA2, 0x89, 0x62,
                 0x6F, 0x6C, 0x74, 0x5F, 0x73, 0x69, 0x70, 0x73, 0xC3, 0x84,
                 _::binary>> = :erlang.iolist_to_binary(Encoder.encode({:run, [query, params]}, unquote(bolt_version)))
      end
    end)
  end
end
