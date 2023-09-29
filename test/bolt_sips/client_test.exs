defmodule Bolt.Sips.ClientTest do
  use ExUnit.Case, async: true
  alias Bolt.Sips.Client

  @opts Bolt.Sips.TestHelper.opts()

  describe "connect" do
    # bolt_basic_auth
    @tag bolt_basic_auth: true
    test "basic auth with password" do
      opts = [username: "neo4j", password: "BoltSipsPassword", versions: [5, 1]] ++ @opts
      assert {:ok, client} = Client.connect(opts)
      assert is_map(client)
      assert is_tuple(client.sock)
      assert 5.1 = client.version
    end
  end
end
