defmodule Bolt.Sips.Internals.BoltProtocolV3Test do
  use ExUnit.Case, async: true
  @moduletag :bolt_v3

  alias Bolt.Sips.Internals.BoltProtocol
  alias Bolt.Sips.Internals.BoltProtocolV3
  alias Bolt.Sips.Metadata

  setup do
    app_config = Application.get_env(:bolt_sips, Bolt)

    port = Keyword.get(app_config, :port, 7687)
    auth = {app_config[:basic_auth][:username], app_config[:basic_auth][:password]}

    config =
      app_config
      |> Keyword.put(:port, port)
      |> Keyword.put(:auth, auth)

    {:ok, port} =
      :gen_tcp.connect(config[:url], config[:port], active: false, mode: :binary, packet: :raw)

    {:ok, _} = BoltProtocol.handshake(:gen_tcp, port, [])

    on_exit(fn ->
      :gen_tcp.close(port)
    end)

    {:ok, config: config, port: port}
  end

  describe "hello/5:" do
    test "ok", %{config: config, port: port} do
      assert {:ok, _} =
               BoltProtocolV3.hello(
                 :gen_tcp,
                 port,
                 3,
                 config[:auth],
                 []
               )
    end

    test "invalid auth", %{config: config, port: port} do
      assert {:error, _} =
               BoltProtocolV3.hello(
                 :gen_tcp,
                 port,
                 3,
                 {config[:basic_auth][:username], "wrong!"},
                 []
               )
    end
  end

  test "goodbye/5", %{config: config, port: port} do
    assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])

    assert :ok = BoltProtocolV3.goodbye(:gen_tcp, port, 3)
  end

  describe "run/7:" do
    test "ok without parameters nor metadata", %{config: config, port: port} do
      assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])

      assert {:ok, {:success, %{"fields" => ["num"]}}} =
               BoltProtocolV3.run(:gen_tcp, port, 3, "RETURN 1 AS num", %{}, %{}, [])
    end

    test "ok without parameters with metadata", %{config: config, port: port} do
      assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])
      {:ok, metadata} = Metadata.new(%{tx_timeout: 10_000})

      assert {:ok, {:success, %{"fields" => ["num"]}}} =
               BoltProtocolV3.run(:gen_tcp, port, 3, "RETURN 1 AS num", %{}, metadata, [])
    end

    test "ok with parameters without metadata", %{config: config, port: port} do
      assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])

      assert {:ok, {:success, %{"fields" => ["num"]}}} =
               BoltProtocolV3.run(:gen_tcp, port, 3, "RETURN {num} AS num", %{num: 5}, %{}, [])
    end

    test "ok with parameters with metadata", %{config: config, port: port} do
      assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])
      {:ok, metadata} = Metadata.new(%{tx_timeout: 10_000})

      assert {:ok, {:success, %{"fields" => ["num"]}}} =
               BoltProtocolV3.run(
                 :gen_tcp,
                 port,
                 3,
                 "RETURN {num} AS num",
                 %{num: 5},
                 metadata,
                 []
               )
    end

    test "returns IGNORED when sending RUN on a FAILURE state", %{config: config, port: port} do
      assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])
      assert {:error, _} = BoltProtocolV3.run(:gen_tcp, port, 3, "Invalid cypher", %{}, %{}, [])

      assert {:error, _} = BoltProtocol.pull_all(:gen_tcp, port, 3, [])
    end

    test "ok after IGNORED and RESET", %{config: config, port: port} do
      assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])
      assert {:error, _} = BoltProtocolV3.run(:gen_tcp, port, 3, "Invalid cypher", %{}, %{}, [])

      assert {:error, _} = BoltProtocol.pull_all(:gen_tcp, port, 3, [])
      :ok = BoltProtocol.reset(:gen_tcp, port, 3, [])

      assert {:ok, {:success, %{"fields" => ["num"]}}} =
               BoltProtocolV3.run(:gen_tcp, port, 3, "RETURN 1 AS num", %{}, %{}, [])

      assert {:ok,
              [
                record: [1],
                success: %{"type" => "r"}
              ]} = BoltProtocol.pull_all(:gen_tcp, port, 3, [])
    end
  end

  test "run_statement/7 (successful)", %{config: config, port: port} do
    assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])

    assert [_ | _] =
             BoltProtocolV3.run_statement(:gen_tcp, port, 3, "RETURN 1 AS num", %{}, %{}, [])
  end

  test "pull_all/4 (successful)", %{config: config, port: port} do
    assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])

    assert {:ok, {:success, %{"fields" => ["num"]}}} =
             BoltProtocolV3.run(:gen_tcp, port, 3, "RETURN 1 AS num", %{}, %{}, [])

    assert {:ok,
            [
              record: [1],
              success: %{"type" => "r"}
            ]} = BoltProtocol.pull_all(:gen_tcp, port, 3, [])
  end

  test "discard_all/4 (successful)", %{config: config, port: port} do
    assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])

    assert {:ok, {:success, %{"fields" => ["num"]}}} =
             BoltProtocolV3.run(:gen_tcp, port, 1, "RETURN 1 AS num", %{}, %{}, [])

    assert :ok = BoltProtocol.discard_all(:gen_tcp, port, 3, [])
  end

  test "reset/4 (successful)", %{config: config, port: port} do
    assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])

    assert {:ok, {:success, %{"fields" => ["num"]}}} =
             BoltProtocolV3.run(:gen_tcp, port, 3, "RETURN 1 AS num", %{}, %{}, [])

    assert :ok = BoltProtocol.reset(:gen_tcp, port, 3, [])
  end

  describe "Transaction management" do
    test "Open a transaction without metadata", %{config: config, port: port} do
      assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])

      {:ok, _} = BoltProtocolV3.begin(:gen_tcp, port, 3, %{}, [])
    end

    # Work only with Neo4j Entreprise
    @tag :entreprise_only
    test "Open a transaction with metadata", %{config: config, port: port} do
      assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])
      {:ok, metadata} = Metadata.new(%{bookmarks: ["neo4j:bookmark:v1:tx234"], tx_timeout: 1_000})

      {:ok, _} = BoltProtocolV3.begin(:gen_tcp, port, 3, metadata, [])
    end

    test "Commit a transaction", %{config: config, port: port} do
      assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])

      {:ok, _} = BoltProtocolV3.begin(:gen_tcp, port, 3, %{}, [])

      assert {:ok, {:success, %{"fields" => ["num"]}}} =
               BoltProtocolV3.run(:gen_tcp, port, 3, "RETURN 1 AS num", %{}, %{}, [])

      assert {:ok, _} = BoltProtocol.pull_all(:gen_tcp, port, 3, [])
      {:ok, %{"bookmark" => _}} = BoltProtocolV3.commit(:gen_tcp, port, 3, [])
    end

    test "Rollback a transaction", %{config: config, port: port} do
      assert {:ok, _} = BoltProtocolV3.hello(:gen_tcp, port, 3, config[:auth], [])

      {:ok, _} = BoltProtocolV3.begin(:gen_tcp, port, 3, %{}, [])

      assert {:ok, {:success, %{"fields" => ["num"]}}} =
               BoltProtocolV3.run(:gen_tcp, port, 3, "RETURN 1 AS num", %{}, %{}, [])

      BoltProtocol.discard_all(:gen_tcp, port, 3, [])
      assert :ok = BoltProtocolV3.rollback(:gen_tcp, port, 3, [])
    end

    # Work only with Neo4j Entreprise
    @tag :entreprise_only
    test "With socket instead of gent_tcp", %{config: config, port: port} do
      assert {:ok, _} = BoltProtocolV3.hello(Bolt.Sips.Socket, port, 3, config[:auth], [])
      {:ok, metadata} = Metadata.new(%{bookmarks: ["neo4j:bookmark:v1:tx234"], tx_timeout: 1_000})

      {:ok, _} = BoltProtocolV3.begin(Bolt.Sips.Socket, port, 3, metadata, [])
    end
  end
end
