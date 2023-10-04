defmodule Bolt.Sips.ClientTest do
  use ExUnit.Case, async: true
  alias Bolt.Sips.Client
  alias Bolt.Sips.BoltProtocol.Versions

  @opts Bolt.Sips.TestHelper.opts()

  describe "connect" do
    @tag last_version: true
    test "multiple versions specified" do
      opts = [versions: [5.3, 4, 3]] ++ @opts
      assert {:ok, client} = Client.connect(opts)
      assert 5.3 = client.version
    end
    @tag last_version: true
    test "unordered versions specified" do
      opts = [versions: [4, 3, 5.3]] ++ @opts
      assert {:ok, client} = Client.connect(opts)
      assert 5.3 = client.version
    end
    @tag last_version: true
    test "no versions specified" do
      opts = [] ++ @opts
      assert {:ok, client} = Client.connect(opts)
      last_version = hd(Versions.latest_versions)
      assert last_version = client.version
    end
    @tag core: true
    test "zero version" do
      opts = [versions: [0]] ++ @opts
      {:error, %Bolt.Sips.Error{code: :version_negotiation_error}} = Client.connect(opts)
    end
    @tag core: true
    test "major version incompatible with the server" do
      opts = [versions: [50]] ++ @opts
      {:error, %Bolt.Sips.Error{code: :version_negotiation_error}} = Client.connect(opts)
    end
    @tag bolt_version: "1.0"
    test "one version specified" do
      opts = [username: "neo4j", password: "BoltSipsPassword", versions: [1]] ++ @opts
      assert {:ok, client} = Client.connect(opts)
      assert is_map(client)
      assert is_tuple(client.sock)
      assert 1.0 = client.version
    end
  end
end
