defmodule Bolt.Sips.BoltProtocol.VersionsTest do
  use ExUnit.Case, async: true
  describe "available_versions/0" do
    @tag core: true
    test "returns a list of available versions" do
      assert Bolt.Sips.BoltProtocol.Versions.available_versions() == [1.0, 2.0, 3.0, 4.0, 4.1, 4.2, 4.3, 4.4, 5.0, 5.1, 5.2, 5.3, 5.4]
    end
  end

  describe "latest_versions/0" do
    @tag core: true
    test "returns the latest versions sorted in descending order" do
      assert Bolt.Sips.BoltProtocol.Versions.latest_versions() == [5.4, 5.3, 5.2, 5.1]
    end
  end

  describe "to_bytes/1" do
    @tag core: true
    test "converts a float version to bytes version" do
      assert Bolt.Sips.BoltProtocol.Versions.to_bytes(5.3) == <<0, 0, 3, 5>>
    end
    @tag core: true
    test "converts an integer version to bytes version" do
      assert Bolt.Sips.BoltProtocol.Versions.to_bytes(5) == <<0, 0, 0, 5>>
    end
  end

end
