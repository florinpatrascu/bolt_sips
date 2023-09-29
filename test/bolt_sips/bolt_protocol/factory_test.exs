defmodule Bolt.Sips.Internals.BoltProtocol.FactoryTest do
  use ExUnit.Case

  describe "create_protocol/1" do
    test "returns the correct protocol module for valid versions" do
      assert {:ok, Bolt.Protocol.V1} = Bolt.Sips.Internals.BoltProtocol.Factory.create_protocol(1)
      assert {:ok, Bolt.Protocol.V1} = Bolt.Sips.Internals.BoltProtocol.Factory.create_protocol(2.0)
      assert {:ok, Bolt.Protocol.V3} = Bolt.Sips.Internals.BoltProtocol.Factory.create_protocol(3)
      assert {:ok, Bolt.Protocol.V5} = Bolt.Sips.Internals.BoltProtocol.Factory.create_protocol(5.0)
    end

    test "returns an error for unsupported versions" do
      assert {:error, "Protocol version 0.9 is not implemented."} = Bolt.Sips.Internals.BoltProtocol.Factory.create_protocol(0.9)
      assert {:error, "Protocol version 6.0 is not implemented."} = Bolt.Sips.Internals.BoltProtocol.Factory.create_protocol(6.0)
    end
  end
end
