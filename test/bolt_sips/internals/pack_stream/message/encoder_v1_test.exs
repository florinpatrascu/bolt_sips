defmodule Bolt.Sips.Internals.PackStream.Message.EncoderV1Test do
  use ExUnit.Case, async: true

  doctest Bolt.Sips.Internals.PackStream.Message.EncoderV1

  alias Bolt.Sips.Internals.PackStream.Message.EncoderV1

  test "Encode ACK_FAILURE" do
    assert <<0x0, 0x2, 0xB0, 0xE, 0x0, 0x0>> ==
             :erlang.iolist_to_binary(EncoderV1.encode({:ack_failure, []}, 1))
  end

  test "Encode DISCARD_ALL" do
    assert <<0x0, 0x2, 0xB0, 0x2F, 0x0, 0x0>> ==
             :erlang.iolist_to_binary(EncoderV1.encode({:discard_all, []}, 1))
  end

  describe "Encode INIT:" do
    test "without params" do
      assert <<0x0, _, 0xB2, 0x1, _::binary>> =
               :erlang.iolist_to_binary(EncoderV1.encode({:init, []}, 1))
    end

    test "with params" do
      assert <<0x0, _, 0xB2, 0x1, _::binary>> =
               :erlang.iolist_to_binary(EncoderV1.encode({:init, [{"neo4j", "test"}]}, 1))
    end
  end

  test "Encode PULL_ALL" do
    assert <<0x0, 0x2, 0xB0, 0x3F, 0x0, 0x0>> ==
             :erlang.iolist_to_binary(EncoderV1.encode({:pull_all, []}, 1))
  end

  test "Encode RESET" do
    assert <<0x0, 0x2, 0xB0, 0xF, 0x0, 0x0>> ==
             :erlang.iolist_to_binary(EncoderV1.encode({:reset, []}, 1))
  end

  describe "Encode RUN:" do
    test "without params" do
      assert <<0x0, 0x13, 0xB2, 0x10, 0x8F, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20, 0x35, 0x20,
               0x41, 0x53, 0x20, 0x6E, 0x75, 0x6D, 0xA0, 0x0,
               0x0>> == :erlang.iolist_to_binary(EncoderV1.encode({:run, ["RETURN 5 AS num"]}, 1))
    end

    test "with params" do
      assert <<0x0, 0x21, 0xB2, 0x10, 0xD0, 0x12, 0x52, 0x45, 0x54, 0x55, 0x52, 0x4E, 0x20, 0x24,
               0x73, 0x74, 0x72, 0x20, 0x41, 0x53, 0x20, 0x73, 0x74, 0x72, 0xA1, 0x83, 0x73, 0x74,
               0x72, 0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x0,
               0x0>> ==
               :erlang.iolist_to_binary(
                 EncoderV1.encode({:run, ["RETURN $str AS str", %{str: "hello"}]}, 1)
               )
    end
  end

  test "fails for unknown message type" do
    assert {:error, :not_implemented} == EncoderV1.encode({:invalid, []}, 1)
  end
end
