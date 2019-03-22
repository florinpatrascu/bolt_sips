defmodule BoltProtocolV1.Sips.Internals.BoltProtocolV1Test do
  use ExUnit.Case, async: true

  alias Bolt.Sips.Internals.BoltProtocolV1
  alias Bolt.Sips.Internals.BoltVersionHelper

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

    on_exit(fn ->
      :gen_tcp.close(port)
    end)

    {:ok, config: config, port: port}
  end

  test "handshake/3", %{port: port} do
    assert {:ok, version} = BoltProtocolV1.handshake(:gen_tcp, port, [])
    assert is_integer(version)
    assert version in BoltVersionHelper.available_versions()
  end

  describe "init/5:" do
    test "ok", %{config: config, port: port} do
      assert {:ok, _bolt_version} = BoltProtocolV1.handshake(:gen_tcp, port, [])

      assert {:ok, _} =
               BoltProtocolV1.init(
                 :gen_tcp,
                 port,
                 1,
                 config[:auth],
                 []
               )
    end

    test "invalid auth", %{config: config, port: port} do
      assert {:ok, _bolt_version} = BoltProtocolV1.handshake(:gen_tcp, port, [])

      assert {:error, _} =
               BoltProtocolV1.init(
                 :gen_tcp,
                 port,
                 1,
                 {config[:basic_auth][:username], "wrong!"},
                 []
               )
    end
  end

  describe "run/6:" do
    test "ok without parameters", %{config: config, port: port} do
      assert {:ok, _bolt_version} = BoltProtocolV1.handshake(:gen_tcp, port, [])
      assert {:ok, _} = BoltProtocolV1.init(:gen_tcp, port, 1, config[:auth], [])

      assert {:ok, {:success, %{"fields" => ["num"]}}} =
               BoltProtocolV1.run(:gen_tcp, port, 1, "RETURN 1 AS num", %{}, [])
    end

    test "ok with parameters", %{config: config, port: port} do
      assert {:ok, _bolt_version} = BoltProtocolV1.handshake(:gen_tcp, port, [])
      assert {:ok, _} = BoltProtocolV1.init(:gen_tcp, port, 1, config[:auth], [])

      assert {:ok, {:success, %{"fields" => ["num"]}}} =
               BoltProtocolV1.run(:gen_tcp, port, 1, "RETURN {num} AS num", %{num: 5}, [])
    end

    test "returns IGNORED when sending RUN on a FAILURE state", %{config: config, port: port} do
      assert {:ok, _bolt_version} = BoltProtocolV1.handshake(:gen_tcp, port, [])
      assert {:ok, _} = BoltProtocolV1.init(:gen_tcp, port, 1, config[:auth], [])
      assert {:error, _} = BoltProtocolV1.run(:gen_tcp, port, 1, "Invalid cypher", %{}, [])

      assert {:error, _} = BoltProtocolV1.pull_all(:gen_tcp, port, 1, [])
    end

    test "ok after IGNORED AND ACK_FAILURE", %{config: config, port: port} do
      assert {:ok, _bolt_version} = BoltProtocolV1.handshake(:gen_tcp, port, [])
      assert {:ok, _} = BoltProtocolV1.init(:gen_tcp, port, 1, config[:auth], [])
      assert {:error, _} = BoltProtocolV1.run(:gen_tcp, port, 1, "Invalid cypher", %{}, [])

      assert {:error, _} = BoltProtocolV1.pull_all(:gen_tcp, port, 1, [])
      :ok = BoltProtocolV1.ack_failure(:gen_tcp, port, 1, [])

      assert {:ok, {:success, %{"fields" => ["num"]}}} =
               BoltProtocolV1.run(:gen_tcp, port, 1, "RETURN 1 AS num", %{}, [])

      assert {:ok,
              [
                record: [1],
                success: %{"type" => "r"}
              ]} = BoltProtocolV1.pull_all(:gen_tcp, port, 1, [])
    end
  end

  test "pull_all/4 (successful)", %{config: config, port: port} do
    assert {:ok, _bolt_version} = BoltProtocolV1.handshake(:gen_tcp, port, [])
    assert {:ok, _} = BoltProtocolV1.init(:gen_tcp, port, 1, config[:auth], [])

    assert {:ok, {:success, %{"fields" => ["num"]}}} =
             BoltProtocolV1.run(:gen_tcp, port, 1, "RETURN 1 AS num", %{}, [])

    assert {:ok,
            [
              record: [1],
              success: %{"type" => "r"}
            ]} = BoltProtocolV1.pull_all(:gen_tcp, port, 1, [])
  end

  test "run_statement/6 (successful)", %{config: config, port: port} do
    assert {:ok, _bolt_version} = BoltProtocolV1.handshake(:gen_tcp, port, [])
    assert {:ok, _} = BoltProtocolV1.init(:gen_tcp, port, 1, config[:auth], [])
    assert [_ | _] = BoltProtocolV1.run_statement(:gen_tcp, port, 1, "RETURN 1 AS num", %{}, [])
  end

  test "discard_all/4 (successful)", %{config: config, port: port} do
    assert {:ok, _bolt_version} = BoltProtocolV1.handshake(:gen_tcp, port, [])
    assert {:ok, _} = BoltProtocolV1.init(:gen_tcp, port, 1, config[:auth], [])

    assert {:ok, {:success, %{"fields" => ["num"]}}} =
             BoltProtocolV1.run(:gen_tcp, port, 1, "RETURN 1 AS num", %{}, [])

    assert :ok = BoltProtocolV1.discard_all(:gen_tcp, port, 1, [])
  end

  test "ack_failure/4 (successful)", %{config: config, port: port} do
    assert {:ok, _bolt_version} = BoltProtocolV1.handshake(:gen_tcp, port, [])
    assert {:ok, _} = BoltProtocolV1.init(:gen_tcp, port, 1, config[:auth], [])
    assert {:error, _} = BoltProtocolV1.run(:gen_tcp, port, 1, "Invalid cypher", %{}, [])
    assert :ok = BoltProtocolV1.ack_failure(:gen_tcp, port, 1, [])
  end

  describe "reset/4" do
    test "ok", %{config: config, port: port} do
      assert {:ok, _bolt_version} = BoltProtocolV1.handshake(:gen_tcp, port, [])
      assert {:ok, _} = BoltProtocolV1.init(:gen_tcp, port, 1, config[:auth], [])

      assert {:ok, {:success, %{"fields" => ["num"]}}} =
               BoltProtocolV1.run(:gen_tcp, port, 1, "RETURN 1 AS num", %{}, [])

      assert :ok = BoltProtocolV1.reset(:gen_tcp, port, 1, [])
    end

    test "ok during process", %{config: config, port: port} do
      assert {:ok, _bolt_version} = BoltProtocolV1.handshake(:gen_tcp, port, [])
      assert {:ok, _} = BoltProtocolV1.init(:gen_tcp, port, 1, config[:auth], [])
      assert {:error, _} = BoltProtocolV1.run(:gen_tcp, port, 1, "Invalid cypher", %{}, [])

      {:error, _} = BoltProtocolV1.pull_all(:gen_tcp, port, 1, [])
      assert :ok = BoltProtocolV1.reset(:gen_tcp, port, 1, [])

      assert {:ok, {:success, %{"fields" => ["num"]}}} =
               BoltProtocolV1.run(:gen_tcp, port, 1, "RETURN 1 AS num", %{}, [])

      assert {:ok, [{:record, _}, {:success, _}]} = BoltProtocolV1.pull_all(:gen_tcp, port, 1, [])
    end
  end
end
