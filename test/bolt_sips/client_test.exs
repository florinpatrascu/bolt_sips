defmodule Bolt.Sips.ClientTest do
  use ExUnit.Case, async: true
  alias Bolt.Sips.Client
  alias Bolt.Sips.BoltProtocol.Versions

  @opts Bolt.Sips.TestHelper.opts()
  @noop_chunk <<0x00, 0x00>>

  describe "connect" do
    @tag bolt_version: "5.3"
    test "multiple versions specified" do
      opts = [versions: [5.3, 4, 3]] ++ @opts
      assert {:ok, client} = Client.connect(opts)
      assert 5.3 = client.bolt_version
    end
    @tag bolt_version: "5.3"
    test "unordered versions specified" do
      opts = [versions: [4, 3, 5.3]] ++ @opts
      assert {:ok, client} = Client.connect(opts)
      assert 5.3 = client.bolt_version
    end
    # TODO: add the latest version tag when it is the latest version being tested
    @tag last_version: true
    test "no versions specified" do
      opts = [] ++ @opts
      assert {:ok, client} = Client.connect(opts)
      last_version = hd(Versions.latest_versions)
      assert last_version = client.bolt_version
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
      opts = [versions: [1]] ++ @opts
      assert {:ok, client} = Client.connect(opts)
      assert is_map(client)
      assert is_tuple(client.sock)
      assert 1.0 = client.bolt_version
    end
  end

  describe "recv_packets" do
    @tag core: true
    test "recv_packets concatenates and decodes two chunks" do
      sizeMock = <<0,10>>
      chunk1 = <<0,14,103,106>>
      chunk2 = <<0,5,107,108,0,0>>
      pid = Bolt.Sips.Mocks.SockMock.start_link([@noop_chunk, sizeMock <> chunk1, sizeMock <> chunk2])
      client = %{sock: {Bolt.Sips.Mocks.SockMock, pid}}
      {:ok, message} = Client.recv_packets(client, fn data -> {:ok, data} end, 0)
      assert message == chunk1 <> chunk2
    end

    @tag core: true
    test "recv_packets decodes a single chunk" do
      sizeMock = <<0,10>>
      chunk1 = <<0,14,103,106,0,0>>
      pid = Bolt.Sips.Mocks.SockMock.start_link([@noop_chunk, sizeMock <> chunk1])
      client = %{sock: {Bolt.Sips.Mocks.SockMock, pid}}
      {:ok, message} = Client.recv_packets(client, fn data -> {:ok, data} end, 0)
      assert message == chunk1
    end

    @tag core: true
    test "ignores noop chunks between two chunks" do
      sizeMock = <<0,10>>
      chunk1 = <<0,14,103,106>>
      chunk2 = <<0,5,107,108,0,0>>
      pid = Bolt.Sips.Mocks.SockMock.start_link([@noop_chunk, sizeMock <> chunk1, @noop_chunk, sizeMock <> chunk2, @noop_chunk])
      client = %{sock: {Bolt.Sips.Mocks.SockMock, pid}}
      {:ok, message} = Client.recv_packets(client, fn data -> {:ok, data} end, 0)
      assert message == chunk1 <> chunk2
    end
  end
end
